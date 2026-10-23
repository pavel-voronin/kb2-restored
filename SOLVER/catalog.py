"""Inventory existing evidence and solve set cover without running the game."""

import hashlib
import itertools
import json
from config import ROOT

ROUTES = ROOT / "SOLVER/ROUTES"

# These are successful gameplay families, not every branch or item combination.
BASE = {
    "campaign",
    "calendar",
    "income",
    "treasure",
    "parchment",
    "wizard",
    "workers",
    "terrain-work",
    "island-portal",
    "tornado",
    "five-map-parts",
    "ship-purchase",
    "boarding",
    "ending",
}
ARMY = {"recruitment", "field-battle", "melee", "shooting", "flight", "enemy-phase"}
OBJECTIVES = {
    "menus": {"help-reports-map", "quicksave"},
    "town": {
        "town-contract",
        "siege-engine-purchase",
        "town-workers",
        "trade",
        "scroll-purchase",
    },
    "cave": {"underground"},
    "castle": {"castle-capture", "garrison"},
    "ritual": {"ritual-search", "guardian-battle", "ritual-learning"},
    "workshop": {"ritual-instructions", "mutant-creation", "mutant-battle"},
    "royal-reward": {"royal-quest", "royal-reward"},
}
OPEN = {
    "save-reload": "Именованное сохранение, перезапуск и загрузка в полном прохождении",
    "sea-landing": "Морской переход и высадка на другом острове",
    "reserve": "Подтверждённый обмен между резервом и полем боя",
    "dismiss": "Увольнение отряда",
    "spirit": "Вызов духа",
    "relics": "Ритуальные принадлежности",
    "defeat-recovery": "Поражение и продолжение кампании до победы",
}


def inventory():
    rows = []
    for path in sorted(ROUTES.glob("*.json")):
        if path.stem.endswith((".proof", ".coverage", ".replay")):
            continue
        w = json.loads(path.read_text(encoding="utf-8"))
        if w.get("status") != {"kind": "exit", "code": 0}:
            continue
        features = set(BASE)
        if "army" in path.stem or "adventure" in path.stem or "workshop" in path.stem:
            features |= ARMY
        army_path = ROUTES / "seed-1-army.json"
        if w["seed"] == 1 and army_path.exists():
            army_inputs = json.loads(army_path.read_text(encoding="utf-8"))["inputs"]
            # The retained call evidence places the won field battle at input 2207.
            if len(w["inputs"]) >= 2207 and w["inputs"][:2207] == army_inputs[:2207]:
                features |= ARMY
        for objective, additions in OBJECTIVES.items():
            if "objective:" + objective in w.get("notes", []):
                features |= additions
        for note in w.get("notes", []):
            if note.startswith("effect:"):
                feature = "gift" if note.startswith("effect:gift-to-") else note[7:]
                features.add("reserve" if feature == "reserve-roundtrip" else feature)
        # The map prefix was exported before objective notes were preserved.
        # These 942 events include the royal audience and all five map parts.
        anchor = ROUTES / "seed-2-quest.json"
        if w["seed"] == 2 and anchor.exists():
            quest_inputs = json.loads(anchor.read_text(encoding="utf-8"))["inputs"]
            if len(w["inputs"]) >= 942 and w["inputs"][:942] == quest_inputs[:942]:
                features |= OBJECTIVES["royal-reward"]
        proof_path = path.with_suffix(".proof.json")
        proof = json.loads(proof_path.read_text()) if proof_path.exists() else {}
        confirmed = proof.get("route_sha256") == hashlib.sha256(
            path.read_bytes()
        ).hexdigest() and {
            x["variant"] for x in proof.get("checks", []) if x["result"] == "010000"
        } == {"CUR", "REF"}
        difficulty = (
            3 if [e["scan"] for e in w["inputs"][:5]] == [28, 80, 80, 80, 28] else None
        )
        rows.append(
            {
                "route": path.name,
                "seed": w["seed"],
                "difficulty": difficulty,
                "sessions": len(w.get("sessions", [w["inputs"]])),
                "inputs": len(w["inputs"]),
                "idle_polls": sum(e.get("idle_polls", 0) for e in w["inputs"]),
                "dos_confirmed": confirmed,
                "checkpoints": proof.get("checks", [{}])[0].get("checkpoints", 0),
                "features": sorted(features),
            }
        )
    return rows


def report():
    rows = inventory()
    candidates = [r for r in rows if r["dos_confirmed"]]
    target = set().union(*(set(r["features"]) for r in candidates))
    universe = (
        BASE
        | ARMY
        | set().union(*OBJECTIVES.values())
        | set(OPEN)
        | {"gift"}
        | {f"adventure-{i}" for i in range(6)}
        | {f"battle-{i}" for i in range(7, 14)}
    )
    selected = []
    for count in range(1, len(candidates) + 1):
        covers = [
            group
            for group in itertools.combinations(candidates, count)
            if set().union(*(set(r["features"]) for r in group)) == target
        ]
        if covers:
            selected = min(covers, key=lambda group: sum(r["inputs"] for r in group))
            break
    baseline = json.loads((ROOT / "SOLVER/BASELINE.json").read_text())
    unchanged = all(
        hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == value
        for path, value in baseline["game_sources"].items()
    )
    return {
        "game_sources_match_recorded_baseline": unchanged,
        "routes": rows,
        "covered_families": len(target),
        "catalog_families": len(universe),
        "coverage_percent": round(100 * len(target & universe) / len(universe), 2),
        "uncovered": sorted(universe - target),
        "minimum_cover_among_confirmed": [r["route"] for r in selected],
        "shortest_saved_by_inputs": min(rows, key=lambda r: r["inputs"])["route"],
        "open_families": {k: v for k, v in OPEN.items() if k not in target},
        "scope": "Successful mechanic families; not all branches, unit types or outcomes.",
    }


if __name__ == "__main__":
    print(json.dumps(report(), ensure_ascii=False, indent=2))
