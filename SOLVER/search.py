"""Incremental scenario search. Completed stages are kept as local checkpoints."""

import argparse
from config import WORK
from play import Play
from solve import solve, finish, ensure_wizard
from state import state


def search(seed, scenario, resume=None):
    from detour import leadership, recruit, field_battle
    from objectives import menus, town, cave, castle, ritual
    from workshop import workshop
    from magic_route import adventure, battles
    from recovery import army_recovery
    from spirit import spirit

    path = WORK / "SEARCH" / f"search-{seed}-{scenario}.json"
    p = (
        Play.resume(resume)
        if resume
        else solve(
            seed,
            scenario="quest" if scenario == "magic" else "economic",
            finish_game=False,
        )
    )

    def army(p):
        leadership(p)
        while state(p.vm).Campaign.MagicPower < 22:
            ensure_wizard(p, 2)
        for species in (20, 23, 17, 18, 22):
            recruit(p, species)
        field_battle(p)

    stages = (
        [
            ("adventure-magic", adventure),
            ("battle-magic", battles),
            ("recovery", army_recovery),
        ]
        if scenario == "magic"
        else [
            ("army", army),
            ("menus", menus),
            ("town", town),
            ("cave", cave),
            ("castle", castle),
            ("ritual", ritual),
            ("workshop", workshop),
            ("spirit", spirit),
        ]
    )
    p.save(path)
    for name, fn in stages:
        tag = "objective:" + name
        if tag in p.notes:
            continue
        checkpoint = p.checkpoint()
        try:
            fn(p)
        except Exception:
            p.rewind(checkpoint)
            p.save(path)
            raise
        if tag not in p.notes:
            p.notes.append(tag)
        p.save(path)
    finish(p, voyage=scenario == "magic")
    winner = WORK / "SEARCH" / f"winner-{seed}-{scenario}.json"
    p.save(winner)
    print("WINNER", winner, flush=True)
    return p


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--scenario", choices=("workshop", "magic"), default="workshop")
    parser.add_argument("--resume")
    args = parser.parse_args()
    search(args.seed, args.scenario, args.resume)
