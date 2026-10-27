"""Negative controls for empty, incomplete and contradictory passing summaries."""
import unittest
from run_regression import validate_output

GOOD = ("SCOREBOARD SUMMARY: PASS=15 FAIL=0\n"
        "READS=8 RESPONSES=8 PASS=80 FAIL=0\n"
        "FUNCTIONAL COVERAGE SUMMARY\n")


class ResultChecks(unittest.TestCase):
    def test_complete_evidence_passes(self):
        self.assertIsNone(validate_output(GOOD))

    def test_silent_monitor_is_rejected(self):
        error = validate_output(GOOD.replace("PASS=15", "PASS=0"))
        self.assertIn("expected 15 checked transactions", error)

    def test_dropped_transaction_is_rejected(self):
        self.assertIsNotNone(validate_output(GOOD.replace("PASS=15", "PASS=14")))

    def test_missing_scoreboard_is_rejected(self):
        self.assertIsNotNone(validate_output(GOOD.split("\n", 1)[1]))

    def test_duplicate_scoreboard_is_rejected(self):
        self.assertIsNotNone(validate_output(GOOD + GOOD.split("\n")[0] + "\n"))

    def test_missing_response_is_rejected(self):
        self.assertIsNotNone(validate_output(GOOD.replace("RESPONSES=8", "RESPONSES=7")))

    def test_zero_protocol_checks_is_rejected(self):
        self.assertIsNotNone(validate_output(GOOD.replace("PASS=80", "PASS=0")))

    def test_explicit_failure_is_rejected(self):
        self.assertIsNotNone(validate_output("[SCB][FAIL] read mismatch\n" + GOOD))

    def test_missing_coverage_summary_is_rejected(self):
        self.assertIsNotNone(validate_output(GOOD.replace("FUNCTIONAL COVERAGE SUMMARY", "")))


if __name__ == "__main__":
    unittest.main()
