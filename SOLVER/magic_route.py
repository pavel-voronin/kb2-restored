"""Discover and exercise scroll effects using purchases and ordinary keys."""

from config import WORK
from objectives import visit
from solve import ensure_wizard
from state import state, summary


def gift_shop(p):
    for attempt in range(12):
        g = state(p.vm).Campaign
        shops = [
            (i + 1, t.X, t.Y) for i in range(5) for t in g.Towns[i] if t.Scroll == 6
        ]
        if shops:
            return shops[0]
        ensure_wizard(p, 6, offer="Изменить волшебства")
        p.settle()
    raise RuntimeError("No gift scroll shop found")


def buy_gift(p, shop):
    visit(p, shop[0], shop[1:])
    before = state(p.vm).Campaign.Scrolls[6]
    p.char("4")
    p.send(28)
    p.send(1)
    if state(p.vm).Campaign.Scrolls[6] != before + 1:
        raise RuntimeError(("Gift purchase failed", p.vm.text[-15:]))


def convert(p, spell):
    before = state(p.vm).Campaign.Scrolls[spell]
    p.send(22)
    p.send(8)
    for _ in range(spell):
        p.send(80)
    p.send(28)
    p.settle()
    if state(p.vm).Campaign.Scrolls[spell] != before + 1:
        raise RuntimeError(("Gift conversion failed", spell))
    p.notes.append("effect:gift-to-" + str(spell))


def adventure(p):
    shop = gift_shop(p)
    print("GIFT SHOP", shop, flush=True)
    for spell in range(6):
        buy_gift(p, shop)
        convert(p, spell)
        before = bytes(state(p.vm).Campaign)
        count = state(p.vm).Campaign.Scrolls[spell]
        p.send(22)
        p.send(spell + 2)
        if spell in (2, 3, 4):
            p.send(28)
        p.settle()
        if state(p.vm).Campaign.Scrolls[spell] != count - 1:
            raise RuntimeError(("Adventure cast failed", spell, p.vm.text[-15:]))
        if bytes(state(p.vm).Campaign) == before:
            raise RuntimeError("No campaign change")
        p.notes.append("effect:adventure-" + str(spell))
        p.save(WORK / "SEARCH/magic-progress.json")
        print("ADVENTURE SPELL", spell, summary(p.vm), flush=True)
    for spell in range(7, 14):
        buy_gift(p, shop)
        convert(p, spell)
    p.save(WORK / "SEARCH/magic-equipped.json")
    return shop


def battles(p):
    """Spend each battle scroll once; retain observed before/after effects."""
    import tactics
    from detour import recruit, field_battle
    from tactics import battle_state, aim

    if not p.vm.battle_active:
        for species in (20, 23, 17, 18, 22):
            recruit(p, species)
            p.save(WORK / "SEARCH/magic-army.json")
    done = {i for i in range(7, 14) if "effect:battle-" + str(i) in p.notes}
    original = tactics.choose
    selected = None
    pending = None
    reserve_done = "effect:reserve-roundtrip" in p.notes

    def flush():
        nonlocal pending
        if pending is None:
            return
        spell, before, oldfield = pending
        after = battle_state(p.vm)
        field = bytes(state(p.vm).Runtime.BattleField)
        effects = {
            7: oldfield != field,
            8: any(
                a.HitPoints > b.HitPoints for a, b in zip(after.Player, before.Player)
            ),
            9: any(
                a.HitPoints < b.HitPoints for a, b in zip(after.Enemy, before.Enemy)
            ),
            10: after.FrozenEnemySlot != before.FrozenEnemySlot,
            11: any(
                a.HitPoints < b.HitPoints for a, b in zip(after.Enemy, before.Enemy)
            ),
            12: any(
                a.HitPoints > b.HitPoints for a, b in zip(after.Player, before.Player)
            ),
            13: list(after.Poison) != list(before.Poison),
        }
        if effects[spell]:
            done.add(spell)
            p.notes.append("effect:battle-" + str(spell))
            print("BATTLE SPELL EFFECT", spell, sorted(done), flush=True)
        pending = None
        p.save(WORK / "SEARCH/magic-active.json")

    def choose(vm):
        nonlocal selected, pending, reserve_done
        flush()
        c = battle_state(vm)
        s = state(vm)
        field = s.Runtime.BattleField
        if not any(32 <= field[xx][yy] <= 44 for xx in range(6) for yy in range(5)):
            return 1 if vm.battle_mode == "magic" else 28
        if not reserve_done and vm.battle_cursor[2] == 0 and vm.battle_mode != "magic":
            before = [a.Species for a in c.Player]
            p.send(30)
            p.char("1")
            p.send(15)
            p.char("2")
            p.send(1)
            if [a.Species for a in battle_state(vm).Player] == before:
                # The same unit returned; withdrawing and restoring it are intentional.
                p.notes.append("effect:reserve-roundtrip")
            reserve_done = True
            c = battle_state(vm)
        if vm.battle_mode == "magic":
            selected = next(
                (
                    i
                    for i in (7, 8, 13, 10, 12, 11, 9)
                    if i not in done and s.Campaign.Scrolls[i]
                ),
                None,
            )
            return selected - 5 if selected is not None else 1
        x, y, color = vm.battle_cursor
        if color == 15 and selected is not None:
            if selected == 7:
                return original(vm)
            players = [
                (xx, yy, (field[xx][yy] - 112) // 3)
                for xx in range(6)
                for yy in range(5)
                if 112 <= field[xx][yy] <= 124
            ]
            enemies = [
                (xx, yy, (field[xx][yy] - 32) // 3)
                for xx in range(6)
                for yy in range(5)
                if 32 <= field[xx][yy] <= 44
            ]
            if selected in (8, 12):
                target = min(
                    players,
                    key=lambda q: (
                        c.Player[q[2]].HitPoints / max(1, c.Player[q[2]].InitialCount)
                    ),
                )
            else:
                target = max(enemies, key=lambda q: c.Enemy[q[2]].HitPoints)
            if (x, y) == target[:2]:
                pending = selected, c, bytes(field)
                selected = None
                return 28
            return aim((x, y), target)
        if (
            color == 0
            and c.EnemyPhaseFinished
            and any(i not in done and s.Campaign.Scrolls[i] for i in range(7, 14))
        ):
            return 22
        if color == 15 and selected == 7:
            return original(vm)
        return original(vm)

    # Teleport has two targets; record the second confirmation separately.
    def controlled(vm):
        nonlocal pending, selected
        if vm.battle_cursor[2] == 15 and selected == 7:
            c = battle_state(vm)
            key = original(vm)
            if key == 28 and c.TeleportSelected:
                pending = 7, c, bytes(state(vm).Runtime.BattleField)
                selected = None
            return key
        return choose(vm)

    tactics.choose = controlled
    try:
        for _ in range(10):
            if p.vm.battle_active:
                tactics.fight(p)
            else:
                field_battle(p)
            flush()
            p.save(WORK / "SEARCH/magic-battles.json")
            if done == set(range(7, 14)):
                return
        raise RuntimeError(
            ("Uncovered battle spells", sorted(set(range(7, 14)) - done))
        )
    except Exception:
        p.save(WORK / "SEARCH/magic-failed.json")
        raise
    finally:
        tactics.choose = original
