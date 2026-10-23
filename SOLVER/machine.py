"""Fast real-mode executor for the separately instrumented TP7 search build.

The guest runs the Pascal game. Host-side search only supplies keyboard input.
Graphics and wall-clock waits are omitted in this exploratory build; a route
must subsequently pass the independent DOS replay before becoming a fixture.
"""

from __future__ import annotations
import collections, copy, re, struct, sys
from pathlib import Path

import unicorn as uc
from unicorn.x86_const import *
from config import WORK

REGS = {
    x: globals()["UC_X86_REG_" + x.upper()]
    for x in (
        "ax",
        "bx",
        "cx",
        "dx",
        "si",
        "di",
        "bp",
        "sp",
        "cs",
        "ds",
        "es",
        "ss",
        "ip",
        "eflags",
    )
}
KEYS = {1: 27, 14: 8, 15: 9, 28: 13, 57: 32, 21: ord("y"), 49: ord("n")}
for sc, ch in zip(range(2, 12), "1234567890"):
    KEYS[sc] = ord(ch)
for first, letters in ((16, "qwertyuiop"), (30, "asdfghjkl"), (44, "zxcvbnm")):
    for scan, ch in enumerate(letters, first):
        KEYS[scan] = ord(ch)


class VM:
    def __init__(self, variant="CUR", seed=12345):
        self.variant = variant
        self.seed = seed
        self.root = WORK / variant
        self.cpu = uc.Uc(uc.UC_ARCH_X86, uc.UC_MODE_16)
        self.cpu.mem_map(0, 0x200000)
        self.loadseg = 0x1000
        self.psp = self.loadseg - 16
        self.base = self.loadseg * 16
        raw = (self.root / "CODE/SGHOST.EXE").read_bytes()
        header = struct.unpack_from("<14H", raw)
        size = (header[2] - 1) * 512 + (header[1] or 512)
        image = bytearray(raw[header[4] * 16 : size])
        for i in range(header[3]):
            off, seg = struct.unpack_from("<HH", raw, header[12] + i * 4)
            p = seg * 16 + off
            struct.pack_into(
                "<H",
                image,
                p,
                (struct.unpack_from("<H", image, p)[0] + self.loadseg) & 65535,
            )
        self.cpu.mem_write(self.base, bytes(image))
        self.cpu.mem_write(self.psp * 16, b"\xcd\x20")
        self.cpu.mem_write(self.psp * 16 + 2, struct.pack("<H", 0x9F00))
        self.cpu.mem_write(self.psp * 16 + 0x2C, struct.pack("<H", 0x800))
        self.cpu.mem_write(0x8000, b"PATH=C:\\\x00\x00\x01\x00C:\\SGHOST.EXE\x00")
        tail = f" {seed}".encode("ascii")
        self.cpu.mem_write(self.psp * 16 + 0x80, bytes([len(tail)]) + tail + b"\r")
        self.cpu.mem_write(0x413, struct.pack("<H", 640))
        self.w("cs", self.loadseg + header[11])
        self.w("ip", header[10])
        self.w("ss", self.loadseg + header[7])
        self.w("sp", header[8])
        self.w("ds", self.psp)
        self.w("es", self.psp)
        self.w("eflags", 0x202)
        self.addresses = {}
        self.queue = collections.deque()
        self.pending = None
        self.text = []
        self.messages = []
        self.dialog = []
        self.header = ""
        self.textpos = (0, 0)
        self.extended = 0
        self.deferred = None
        self.files = {}
        self.nextfd = 5
        self.disk = {
            p.name.upper(): p.read_bytes()
            for p in (self.root / "DATA").iterdir()
            if p.is_file()
        }
        self.dta = self.psp * 16 + 0x80
        self.output = ""
        self.steps = 0
        self.coverage = collections.Counter()
        self.battle_cursor = None
        self.battle_mode = None
        self.battle_active = False
        self.battle_spell = 0
        self.symbols = []
        maptext = (self.root / "CODE/SGHOST.MAP").read_text(errors="replace")
        self.data_start = self.base + int(
            re.search(
                r"([0-9A-F]+)H\s+[0-9A-F]+H\s+[0-9A-F]+H\s+DATA\s+DATA", maptext
            ).group(1),
            16,
        )
        for line in (
            (self.root / "CODE/SGHOST.MAP").read_text(errors="replace").splitlines()
        ):
            m = re.match(r"\s+([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)\s*$", line)
            if m:
                self.symbols.append(
                    (self.base + int(m[1], 16) * 16 + int(m[2], 16), m[3])
                )
        self.symbols.sort()
        self.cpu.hook_add(uc.UC_HOOK_INTR, self.interrupt)
        self.cpu.hook_add(
            uc.UC_HOOK_INSN, lambda c, p, s, u: 0, None, 1, 0, UC_X86_INS_IN
        )
        self.cpu.hook_add(
            uc.UC_HOOK_INSN, lambda c, p, s, v, u: None, None, 1, 0, UC_X86_INS_OUT
        )

    def observe_calls(self, names):
        """Host-side execution hooks; no guest bytes or registers are changed."""
        for address, name in self.symbols:
            if name in names:
                self.cpu.hook_add(
                    uc.UC_HOOK_CODE,
                    lambda c, a, z, n: self.coverage.update([n]),
                    name,
                    address,
                    address,
                )

    def r(self, name):
        return self.cpu.reg_read(REGS[name])

    def w(self, name, value):
        self.cpu.reg_write(
            REGS[name], value & (0xFFFFFFFF if name == "eflags" else 65535)
        )

    def read(self, addr, n):
        return bytes(self.cpu.mem_read(addr, n))

    def word(self, addr):
        return struct.unpack("<H", self.read(addr, 2))[0]

    def string(self, addr):
        data = self.read(addr, 260)
        return data.split(b"\0", 1)[0].decode("cp866")

    def carry(self, yes=False):
        self.w("eflags", (self.r("eflags") & ~1) | int(yes))

    def stop(self, kind, **data):
        self.pending = {"kind": kind, **data}
        self.cpu.emu_stop()

    def key(self, scan):
        return (scan, KEYS.get(scan, 0))

    def context(self):
        ss = self.r("ss") * 16
        bp = self.r("bp")
        frames = []
        for _ in range(8):
            if bp > 65530:
                break
            ret = self.word(ss + bp + 2) + 16 * self.word(ss + bp + 4)
            label = next((n for a, n in reversed(self.symbols) if a <= ret), "?")
            frames.append((label, hex(ret)))
            parent = self.word(ss + bp)
            if parent <= bp or parent - bp > 12000:
                break
            bp = parent
        return frames

    def interrupt(self, c, number, user):
        ax = self.r("ax")
        ah = ax >> 8
        al = ax & 255
        if number == 0xF0:
            if ax in (0xF010, 0xF011):
                if ax == 0xF011:
                    if self.deferred is not None:
                        self.queue.append(self.deferred)
                        self.deferred = None
                    self.w("ax", int(bool(self.queue)))
                elif self.extended:
                    self.w("ax", self.extended)
                    self.extended = 0
                elif self.queue:
                    self.w("ax", self.queue.popleft()[1])
                else:
                    self.stop("key", mode="char", frames=self.context())
                return
            kind = ax & 0xFFF
            addr = self.r("bx") * 16 + self.r("cx")
            size = self.r("dx")
            if kind == 14:
                self.textpos = (self.r("bx"), self.r("cx"))
            elif kind == 13:
                if self.r("cx") >= 200:
                    self.dialog = []
            elif kind in (0, 4, 5, 6, 7):
                self.addresses[kind] = (addr, size)
            elif kind == 8:
                self.battle_cursor = (self.r("bx"), self.r("cx"), size)
                self.battle_mode = "cell"
                self.battle_active = True
                if hasattr(self, "on_cell"):
                    self.on_cell(self)
            elif kind == 9:
                self.battle_active = False
                self.battle_mode = None
            elif kind == 18:
                self.battle_spell = size
            elif kind == 10:
                self.battle_mode = "magic"
            elif kind == 12:
                raw = self.read(addr, size)
                text = raw[1 : 1 + raw[0]].decode("cp866")
                self.text.append(text)
                self.messages.append(text)
                if self.textpos[1] >= 200:
                    self.dialog.append(text)
                if self.textpos[1] == 8:
                    self.header = text
                if len(self.text) > 150:
                    self.text = self.text[-100:]
            elif kind == 1:
                self.steps += 1
                self.dialog = []
                self.stop("step")
            elif kind in (2, 3):
                self.stop("victory" if kind == 2 else "death")
            else:
                self.stop("event", event=kind, address=addr, size=size)
            return
        if number == 0x16:
            if ah == 0:
                if self.queue:
                    sc, ch = self.queue.popleft()
                    self.w("ax", sc * 256 + ch)
                else:
                    self.stop("key", mode="scan", frames=self.context())
            elif ah == 1:
                flags = self.r("eflags")
                self.w("eflags", flags & ~0x40 if self.queue else flags | 0x40)
                if self.queue:
                    sc, ch = self.queue[0]
                    self.w("ax", sc * 256 + ch)
                else:
                    self.stop("key", mode="poll", frames=self.context())
            else:
                raise RuntimeError(f"INT16 {ax:04x}")
            return
        if number == 0x10:
            if ah == 0xF:
                self.w("ax", 0x5003)
            elif ah == 0x12:
                self.w("bx", 3)
            return
        if number == 0x1A:
            self.w("cx", 0)
            self.w("dx", 100)
            return
        if number == 0x17:
            return
        if number in (0, 4, 5, 6):
            self.stop("fault", interrupt=number, frames=self.context())
            return
        if number != 0x21:
            raise RuntimeError(f"INT {number:02x} ax={ax:04x}")
        self.carry(False)
        if ah == 0x30:
            self.w("ax", 0x0005)
            return
        if ah == 0x35:
            self.w("bx", self.word(al * 4))
            self.w("es", self.word(al * 4 + 2))
            return
        if ah == 0x25:
            self.cpu.mem_write(al * 4, struct.pack("<HH", self.r("dx"), self.r("ds")))
            return
        if ah == 0x4A:
            return
        if ah == 0x48:
            self.w("ax", 0x9000)
            return
        if ah == 0x49:
            return
        if ah == 0x62:
            self.w("bx", self.psp)
            return
        if ah in (0x4C, 0):
            self.stop("exit", code=al)
            return
        if ah == 0x1A:
            self.dta = self.r("ds") * 16 + self.r("dx")
            return
        if ah == 0x2F:
            self.w("es", self.dta >> 4)
            self.w("bx", self.dta & 15)
            return
        if ah == 0x19:
            self.w("ax", 2)
            return
        if ah == 0xE:
            self.w("ax", 3)
            return
        if ah == 0x2A:
            self.w("cx", 1993)
            self.w("dx", 0x0101)
            self.w("ax", 5)
            return
        if ah == 0x2C:
            self.w("cx", 0x0100)
            self.w("dx", 0)
            return
        if ah == 0x09:
            s = (
                self.read(self.r("ds") * 16 + self.r("dx"), 1024)
                .split(b"$", 1)[0]
                .decode("cp866")
            )
            self.output += s
            return
        if ah in (0x02, 0x06):
            self.output += chr(self.r("dx") & 255)
            return
        if ah in (0x3C, 0x3D):
            name = self.string(self.r("ds") * 16 + self.r("dx")).split("\\")[-1].upper()
            if ah == 0x3D and name not in self.disk:
                self.carry(True)
                self.w("ax", 2)
                return
            if ah == 0x3C:
                self.disk[name] = b""
            fd = self.nextfd
            self.nextfd += 1
            self.files[fd] = [name, 0]
            self.w("ax", fd)
            return
        if ah == 0x3E:
            self.files.pop(self.r("bx"), None)
            return
        if ah == 0x42:
            f = self.files[self.r("bx")]
            delta = (self.r("cx") << 16) | self.r("dx")
            if delta & 0x80000000:
                delta -= 0x100000000
            f[1] = delta + (0 if al == 0 else f[1] if al == 1 else len(self.disk[f[0]]))
            self.w("ax", f[1] & 65535)
            self.w("dx", f[1] >> 16)
            return
        if ah in (0x3F, 0x40):
            fd = self.r("bx")
            n = self.r("cx")
            addr = self.r("ds") * 16 + self.r("dx")
            if fd < 5:
                if ah == 0x40:
                    self.output += self.read(addr, n).decode("cp866")
                else:
                    raise RuntimeError("DOS stdin read")
                self.w("ax", n)
                return
            f = self.files[fd]
            buf = self.disk[f[0]]
            if ah == 0x3F:
                data = buf[f[1] : f[1] + n]
                self.cpu.mem_write(addr, data)
                self.w("ax", len(data))
                f[1] += len(data)
            else:
                data = self.read(addr, n)
                self.disk[f[0]] = buf[: f[1]] + data + buf[f[1] + n :]
                f[1] += n
                self.w("ax", n)
            return
        if ah == 0x43:
            self.w("cx", 0)
            return
        if ah in (0x4E, 0x4F):
            self.carry(True)
            self.w("ax", 2 if ah == 0x4E else 18)
            return
        if ah == 0x44:
            self.w("dx", 0x80D3)
            return
        if ah == 0x57:
            self.w("cx", 0)
            self.w("dx", 0x1821)
            return
        if ah == 0x59:
            self.w("ax", 2)
            return
        if ah == 0x36:
            self.w("ax", 8)
            self.w("bx", 10000)
            self.w("cx", 512)
            self.w("dx", 20000)
            return
        raise RuntimeError(f"INT21 {ax:04x} at {self.r('cs'):04x}:{self.r('ip'):04x}")

    def run(self, scan=None, idle_polls=0):
        previous = self.pending
        self.pending = None
        self.messages = []
        if scan is not None:
            sc, ch = self.key(scan)
            if previous and previous["kind"] == "key" and previous["mode"] == "poll":
                self.queue.append((sc, ch))
                self.w("eflags", self.r("eflags") & ~0x40)
            elif previous and previous["kind"] == "key":
                self.w("ax", ch if previous["mode"] == "char" else sc * 256 + ch)
                if previous["mode"] == "char" and ch == 0:
                    self.extended = sc
            else:
                if idle_polls:
                    assert 7 in self.addresses
                    self.cpu.mem_write(
                        self.addresses[7][0], struct.pack("<I", idle_polls)
                    )
                    self.deferred = (sc, ch)
                else:
                    self.queue.append((sc, ch))
        try:
            self.cpu.emu_start(
                self.r("cs") * 16 + self.r("ip"), 0, timeout=120_000_000, count=0
            )
        except Exception as e:
            raise RuntimeError(
                f"{e}\n{self.r('cs'):04x}:{self.r('ip'):04x} {self.context()} output={self.output!r}"
            ) from e
        if self.pending is None:
            self.pending = {"kind": "limit", "cs": self.r("cs"), "ip": self.r("ip")}
        return self.pending

    def snapshot(self):
        return (
            self.cpu.context_save(),
            (
                self.read(0, self.base),
                self.read(self.data_start, 0xA0000 - self.data_start),
            ),
            copy.deepcopy(
                (
                    self.addresses,
                    self.queue,
                    self.pending,
                    self.files,
                    self.disk,
                    self.nextfd,
                    self.text,
                    self.steps,
                    self.coverage,
                    self.dialog,
                    self.header,
                    self.textpos,
                    self.extended,
                    self.deferred,
                    self.battle_cursor,
                    self.battle_mode,
                    self.battle_active,
                    self.battle_spell,
                )
            ),
        )

    def restore(self, snapshot):
        context, memory, other = snapshot
        self.cpu.context_restore(context)
        self.cpu.mem_write(0, memory[0])
        self.cpu.mem_write(self.data_start, memory[1])
        (
            self.addresses,
            self.queue,
            self.pending,
            self.files,
            self.disk,
            self.nextfd,
            self.text,
            self.steps,
            self.coverage,
            self.dialog,
            self.header,
            self.textpos,
            self.extended,
            self.deferred,
            self.battle_cursor,
            self.battle_mode,
            self.battle_active,
            self.battle_spell,
        ) = copy.deepcopy(other)


if __name__ == "__main__":
    vm = VM(sys.argv[1] if len(sys.argv) > 1 else "CUR")
    event = vm.run()
    print(event, vm.text[-8:], vm.addresses)
    for sc in [28, 80, 80, 80, 28]:
        event = vm.run(sc)
        print(event, vm.text[-8:])
