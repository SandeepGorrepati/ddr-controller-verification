#!/usr/bin/env python3
"""Run DDR verification regression using Icarus Verilog."""
from __future__ import annotations

import subprocess
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
PROOF = ROOT / "proof"
OUT = BUILD / "ddr_verif_env_modular.out"
LOG = PROOF / "ddr_regression.log"

SOURCES = [
    "rtl/ddr_controller.sv",
    "tb/ddr_if.sv",
    "tb/generator.sv",
    "tb/driver.sv",
    "tb/monitor.sv",
    "tb/scoreboard.sv",
    "tb/ddr_assertions.sv",
    "tb/coverage_tracker.sv",
    "tb/tb_top.sv",
]


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)


EXPECTED_SCOREBOARD_CHECKS = 15  # tb/generator.sv: NUM_TXNS
EXPECTED_DIRECTED_READS = 8      # default serialized directed stimulus


def validate_output(output: str) -> str | None:
    """Reject vacuous/truncated passes, even when the simulator exits zero."""
    import re
    if "[SCB][FAIL]" in output or "CHECK FAIL" in output or re.search(r"FAIL=[1-9]", output):
        return "checker failure"
    if "SVA FAIL" in output or "ASSERTION FAIL" in output:
        return "assertion failure"
    summaries = re.findall(r"^SCOREBOARD SUMMARY: PASS=(\d+) FAIL=(\d+)\s*$",
                           output, re.MULTILINE)
    if len(summaries) != 1:
        return "expected exactly one scoreboard summary"
    passed, failed = map(int, summaries[0])
    if passed != EXPECTED_SCOREBOARD_CHECKS or failed:
        return f"expected {EXPECTED_SCOREBOARD_CHECKS} checked transactions, got PASS={passed} FAIL={failed}"
    protocols = re.findall(r"^READS=(\d+) RESPONSES=(\d+) PASS=(\d+) FAIL=(\d+)\s*$",
                           output, re.MULTILINE)
    if len(protocols) != 1:
        return "expected exactly one protocol summary"
    reads, responses, cycles, failures = map(int, protocols[0])
    if reads != EXPECTED_DIRECTED_READS or responses != reads or cycles <= 0 or failures:
        return f"incomplete protocol checks: reads={reads} responses={responses} cycles={cycles} failures={failures}"
    if "FUNCTIONAL COVERAGE SUMMARY" not in output:
        return "coverage summary missing"
    return None


def main() -> int:
    BUILD.mkdir(exist_ok=True)
    PROOF.mkdir(exist_ok=True)

    compile_cmd = ["iverilog", "-g2012", "-gsupported-assertions", "-Wall", "-o", str(OUT), *SOURCES]
    sim_cmd = ["vvp", str(OUT)]

    compile_res = run(compile_cmd, ROOT)
    if compile_res.returncode != 0:
        LOG.write_text("COMPILE FAILED\n" + compile_res.stdout)
        print(compile_res.stdout)
        return compile_res.returncode

    sim_res = run(sim_cmd, ROOT)
    LOG.write_text(sim_res.stdout)
    print(sim_res.stdout)

    if sim_res.returncode != 0:
        print("REGRESSION FAILED: simulator exited nonzero")
        return 1
    failure = validate_output(sim_res.stdout)
    if failure is not None:
        print(f"REGRESSION FAILED: {failure}")
        return 1

    print(f"REGRESSION PASSED: log saved to {LOG}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

