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
    return subprocess.run(cmd, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)


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

    bad_markers = ["SVA FAIL", "ASSERTION FAIL", "[SCB][FAIL]", "FAIL="]
    if "SCOREBOARD SUMMARY" not in sim_res.stdout:
        print("REGRESSION FAILED: scoreboard summary missing")
        return 1
    if "FAIL=0" not in sim_res.stdout:
        print("REGRESSION FAILED: non-zero scoreboard failures")
        return 1
    if "SVA FAIL" in sim_res.stdout or "ASSERTION FAIL" in sim_res.stdout:
        print("REGRESSION FAILED: assertion failure detected")
        return 1
    if "FUNCTIONAL COVERAGE SUMMARY" not in sim_res.stdout:
        print("REGRESSION FAILED: coverage summary missing")
        return 1

    print(f"REGRESSION PASSED: log saved to {LOG}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
