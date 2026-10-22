# Upgrade validation - 2026-10-22

Validated code commit: 822d3e48dd659bdae476930ffb3e4c6caba369e0. Directed scoreboard 15/15; streaming oracle 2,200 cycles and 1,329 responses. Protocol summaries reset each epoch.

[Recorded GitHub Actions run](https://github.com/SandeepGorrepati/ddr-controller-verification/actions/runs/39752332699). Subsequent documentation or path-filter changes do not extend the tested functionality. Re-run the workflow after code changes. Full logs are retained as Actions artifacts subject to GitHub retention limits.

## Observed log excerpts

```text
SCOREBOARD SUMMARY: PASS=15 FAIL=0
FUNCTIONAL COVERAGE SUMMARY
DDR PROTOCOL CHECK SUMMARY
READS=8 RESPONSES=8 PASS=80 FAIL=0
PASS: memory oracle cycles=2200 responses=1329; pipelined reads, mixed writes, reset
DDR PROTOCOL CHECK SUMMARY
READS=725 RESPONSES=725 PASS=1199 FAIL=0
```

These are observed excerpts, not illustrative expected output. Passing this finite suite does not establish exhaustive correctness.

