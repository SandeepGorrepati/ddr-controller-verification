"""Confirm an actual silenced monitor cannot produce a successful regression."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    source = ROOT / "tb" / "monitor.sv"
    original = source.read_text(encoding="utf8")
    # Both observed write/read outputs are suppressed; stimulus and DUT are unchanged.
    old = "act_valid <= 1'b1;"
    # Preserve arbitrary spacing in the two assignments.
    import re
    mutated, count = re.subn(r"act_valid\s*<=\s*1'b1;", "act_valid <= 1'b0;", original)
    if count != 2:
        raise RuntimeError(f"expected two monitor-output anchors, got {count}")
    with tempfile.TemporaryDirectory(prefix="memory-monitor-mutation-") as directory:
        copy = Path(directory) / "repo"
        shutil.copytree(ROOT, copy, ignore=shutil.ignore_patterns(
            ".git", "build", "__pycache__", "*.vcd"))
        (copy / "tb" / "monitor.sv").write_text(mutated, encoding="utf8")
        result = subprocess.run([sys.executable, str(copy / "scripts" / "run_regression.py")],
                                cwd=copy, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=90)
        (ROOT / "proof").mkdir(exist_ok=True)
        (ROOT / "proof" / "monitor_mutation.log").write_text(result.stdout, encoding="utf8")
        expected = "expected 15 checked transactions, got PASS=0 FAIL=0"
        if result.returncode == 0 or expected not in result.stdout:
            raise RuntimeError("silent monitor escaped, or failed for an unrelated reason")
    if source.read_text(encoding="utf8") != original:
        raise RuntimeError("production monitor changed")
    print("PASS: silenced real monitor rejected despite simulator zero exit and FAIL=0")


if __name__ == "__main__":
    main()
