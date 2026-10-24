#!/usr/bin/env python3
"""Line-coverage gate for Recito's non-View code.

Reads an `xccov view --report --json` document on stdin, keeps the files of
target Recito.app that live under Recito/ (minus the exclusions below), prints
a per-file table sorted by ascending coverage, and exits 1 when the combined
line coverage is below --min.

Exit codes: 0 pass, 1 below threshold, 2 bad input or arguments.
"""

import argparse
import json
import os
import sys

TARGET = "Recito.app"
SOURCE_DIR = "Recito"

# Paths relative to Recito/. A trailing "/" excludes a whole directory.
EXCLUDED = (
    "Views/",
    "RecitoApp.swift",
    "App/RootView.swift",
    "App/UITestFixtures.swift",
    "Speech/SFSpeechSource.swift",
    "Speech/SpeechAnalyzerSource.swift",
    "Utilities/KeepAwake.swift",
    "DesignSystem/FoldGeometry.swift",
)


def fail(message, code=2):
    print(f"coverage-gate: {message}", file=sys.stderr)
    sys.exit(code)


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--min", type=float, default=0.80, dest="minimum",
                        help="minimum line coverage as a fraction (default 0.80)")
    parser.add_argument("--root", default=None,
                        help="repository root (default: parent of this script)")
    args = parser.parse_args(argv)
    if not 0.0 <= args.minimum <= 1.0:
        parser.error("--min must be between 0 and 1")
    if args.root is None:
        args.root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return args


def relative_source_path(path, root):
    """Path relative to Recito/, or None when the file is not app source."""
    prefix = os.path.join(os.path.realpath(root), SOURCE_DIR) + os.sep
    real = os.path.realpath(path)
    if real.startswith(prefix):
        return real[len(prefix):]
    # Result built from another checkout: fall back to the last /Recito/.
    marker = os.sep + SOURCE_DIR + os.sep
    index = path.rfind(marker)
    return path[index + len(marker):] if index >= 0 else None


def is_excluded(relative):
    return any(
        relative.startswith(rule) if rule.endswith("/") else relative == rule
        for rule in EXCLUDED
    )


def collect(report, root):
    targets = report.get("targets") if isinstance(report, dict) else None
    if not isinstance(targets, list):
        fail("input is not an xccov report (missing 'targets')")
    target = next((t for t in targets if t.get("name") == TARGET), None)
    if target is None:
        names = ", ".join(str(t.get("name")) for t in targets) or "none"
        fail(f"target {TARGET} not found in report (targets: {names})")

    rows = []
    for entry in target.get("files", []):
        relative = relative_source_path(entry.get("path", ""), root)
        if relative is None or is_excluded(relative):
            continue
        executable = int(entry.get("executableLines", 0))
        covered = int(entry.get("coveredLines", 0))
        rows.append((relative, covered, executable))
    return rows


def render(rows):
    covered = sum(r[1] for r in rows)
    executable = sum(r[2] for r in rows)
    ratio = covered / executable if executable else 0.0

    width = max((len(r[0]) for r in rows), default=4)
    print(f"{'File'.ljust(width)}  {'Cover':>7}  {'Lines':>11}")
    for relative, cov, exe in sorted(rows, key=lambda r: (r[1] / r[2] if r[2] else 1.0, r[0])):
        pct = f"{100 * cov / exe:6.1f}%" if exe else "   n/a "
        print(f"{relative.ljust(width)}  {pct}  {cov:>5}/{exe:<5}")
    print("-" * (width + 22))
    print(f"{'TOTAL'.ljust(width)}  {100 * ratio:6.1f}%  {covered:>5}/{executable:<5}")
    return ratio


def main(argv):
    args = parse_args(argv)
    try:
        report = json.load(sys.stdin)
    except json.JSONDecodeError as error:
        fail(f"stdin is not valid JSON: {error}")

    rows = collect(report, args.root)
    if not rows or sum(r[2] for r in rows) == 0:
        fail("no gated source files found in the report")

    ratio = render(rows)
    if ratio + 1e-12 < args.minimum:
        print(f"FAIL: line coverage {100 * ratio:.2f}% is below {100 * args.minimum:.0f}%")
        return 1
    print(f"PASS: line coverage {100 * ratio:.2f}% (minimum {100 * args.minimum:.0f}%)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
