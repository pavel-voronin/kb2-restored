"""Measure actual calls along a transcript; do not run the route planner."""

import argparse, json, hashlib
from pathlib import Path
from machine import VM
from state import summary

CALLS = "PrepareCampaign EndWeek WorkersMenu WizardVisit AdventureMagic SearchRitualSpell HeroStatus RitualSpellReport CastTornado CargoReport CurrentContract SeaVoyage TreasureVisit UndergroundVisit WanderingArmyVisit BoardShip SandLanding RitualGuardianVisit RegrowMountain AdventureHelp Credits DwellingVisit CastleVisit VictoryReport DefeatReport Battle PaintBattleTerrain BattleHelp ReserveMenu CheckLeadership UncontrolledTurn EnemyPhase ResolveStrike AttackUnit RelocateUnit ShootUnit MovePlayerUnit NextPlayerUnit SelectSpellTarget MagicMenu ApplyDamage TownVisit PaperScrollVisit BlackMage TalkingStoneVisit MapVisit PrepareSave WriteCampaign ReadCampaign SaveNamedGame ArmyOverview DismissArmy GameOver".split()


def measure(path):
    out = Path(path).with_suffix(".coverage.json")
    proof_path = Path(path).with_suffix(".proof.json")
    digest = hashlib.sha256(Path(path).read_bytes()).hexdigest()
    if out.exists() and proof_path.exists():
        proof = json.loads(proof_path.read_text(encoding="utf-8"))
        if proof.get("route_sha256") == digest:
            print("SAVED COVERAGE", Path(path).name, flush=True)
            return json.loads(out.read_text(encoding="utf-8"))
    w = json.loads(Path(path).read_text(encoding="utf-8"))
    vm = VM("CUR", w["seed"])
    vm.observe_calls(CALLS)
    vm.run()
    evidence = {}
    for n, e in enumerate(w["inputs"], 1):
        vm.run(e["scan"], idle_polls=e.get("idle_polls", 0))
        for name, count in vm.coverage.items():
            if count and name not in evidence:
                evidence[name] = {"input": n, "calls": count}
        if n % 500 == 0:
            print("coverage", n, "/", len(w["inputs"]), flush=True)
    result = {
        "seed": w["seed"],
        "inputs": len(w["inputs"]),
        "idle_polls": sum(e.get("idle_polls", 0) for e in w["inputs"]),
        "ending": vm.pending,
        "summary": summary(vm),
        "calls": dict(sorted(vm.coverage.items())),
        "first_call": evidence,
        "not_called": sorted(set(CALLS) - set(vm.coverage)),
    }
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
    return result


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("witness")
    args = a.parse_args()
    measure(args.witness)
