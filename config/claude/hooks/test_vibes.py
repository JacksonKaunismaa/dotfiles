#!/usr/bin/env python3
"""Regression tests for the vibes classifier.

Run:  python test_vibes.py
      python test_vibes.py -v          (show every case)
      python test_vibes.py --add       (interactively add a new case)

Golden cases live in vibes_golden.jsonl — one JSON object per line:
  {"msg": "...", "expected": "frustrated|excited|confused|neutral", "note": "why"}

When you hit a misclassification, add a case, fix the classifier, and re-run.
"""

import argparse
import json
import sys
from pathlib import Path

from vibes import classify

GOLDEN_PATH = Path.home() / "Work-Stuff" / "claude-sandbox" / "vibes_golden.jsonl"


def load_cases() -> list[dict]:
    cases = []
    for i, line in enumerate(GOLDEN_PATH.read_text().splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            cases.append(json.loads(line))
        except json.JSONDecodeError as e:
            print(f"Bad JSON on line {i}: {e}", file=sys.stderr)
            sys.exit(1)
    return cases


def run_tests(verbose: bool = False) -> bool:
    cases = load_cases()
    passed = 0
    failed = 0

    for i, case in enumerate(cases, 1):
        msg = case["msg"]
        expected = case["expected"]
        note = case.get("note", "")
        actual = classify(msg)

        if actual == expected:
            passed += 1
            if verbose:
                print(f"  PASS [{i}] {expected:11s}  {note}")
        else:
            failed += 1
            preview = msg[:70] + ("..." if len(msg) > 70 else "")
            print(f"  FAIL [{i}] expected={expected}, got={actual}")
            print(f"         msg: {preview}")
            if note:
                print(f"         note: {note}")

    total = passed + failed
    print(f"\n{passed}/{total} passed", end="")
    if failed:
        print(f", {failed} FAILED")
    else:
        print(" — all good!")
    return failed == 0


def add_case() -> None:
    print("Add a new golden case.\n")
    msg = input("Message: ").strip()
    if not msg:
        print("Empty message, aborting.")
        return

    actual = classify(msg)
    print(f"Classifier says: {actual}")

    expected = input(f"Expected label [{actual}]: ").strip() or actual
    if expected not in ("frustrated", "excited", "confused", "neutral"):
        print(f"Invalid label: {expected}")
        return

    note = input("Note (optional): ").strip()

    case = {"msg": msg, "expected": expected}
    if note:
        case["note"] = note

    with open(GOLDEN_PATH, "a") as f:
        f.write(json.dumps(case) + "\n")

    status = "PASS" if actual == expected else f"FAIL (classifier says {actual})"
    print(f"Added. Current status: {status}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Vibes classifier regression tests")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show every case")
    parser.add_argument("--add", action="store_true", help="Interactively add a new case")
    args = parser.parse_args()

    if args.add:
        add_case()
    else:
        success = run_tests(verbose=args.verbose)
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
