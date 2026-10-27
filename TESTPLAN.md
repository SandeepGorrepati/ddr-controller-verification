# Request/response memory verification test plan

## Contract under test

This repository verifies a simplified 256×32 memory, not a DDR4 controller or PHY.
There are no DRAM banks, ACT/PRE commands, refresh, bursts or DDR timing parameters.

| Interface behavior | Expected result |
|---|---|
| Request acceptance | req_valid && req_ready at a rising edge; req_ready is always 1 |
| Write | Updates one word; does not generate a response |
| Read | Read accepted at edge N produces resp_valid/data after edge N+1 |
| Consecutive reads | One response per cycle after the initial latency |
| Read completion and write to the same word | Response observes pre-write data on the completion edge |
| Asynchronous active-high reset | Clears memory and cancels outstanding reads |
| Response flow | No backpressure, transaction IDs or reordering |

## Verification layers and traceability

| Feature | Executed source / checker | Scope |
|---|---|---|
| Reset-zero reads, write/readback and overwrites | Modular generator/driver/monitor/scoreboard, tb/tb_top.sv | Directed serialized environment |
| Operation/address/cross activity | tb/coverage_tracker.sv | Manual counters for their defined bins |
| Exact response timing and missing/spurious responses | tb/ddr_assertions.sv | Procedural edge-sampled checks; not concurrent SVA declarations |
| Known accepted address/control/write data and known response data | tb/ddr_assertions.sv | Procedural $isunknown checks and $fatal on failure |
| Pipelined reads, mixed traffic, repeated/boundary addresses and reset during traffic | scripts/gen_stress.py + tb/tb_stress.sv | Independent Python cycle oracle; real-DUT comparison |
| Data integrity and response-valid on every stress cycle | tb/tb_stress.sv samples after nonblocking updates | Exact expected valid/data, not a 1–4-cycle tolerance |

The procedural checker samples before the DUT's nonblocking updates. Its two
accept-history registers account for that sampling phase; they do not describe
two cycles of post-edge DUT latency. The stress test samples after the updates
and directly checks the one-cycle contract.

The current checker does not define the former
`p_read_response_within_4_cycles` or other named concurrent properties.
The older test-plan descriptions and older logs are not the current contract.

## Reproduce the modular regression

```bash
python3 scripts/run_regression.py
```

The script compiles the modular environment, runs it with a timeout, saves
`proof/ddr_regression.log`, and rejects compile/simulator errors, checker
failures, missing summaries and nonzero failure counts.

## Reproduce the independent streaming regression

```bash
python3 scripts/gen_stress.py
iverilog -g2012 -s tb_stress -o build/stress rtl/ddr_controller.sv tb/ddr_assertions.sv tb/tb_stress.sv
vvp build/stress
```

For seed 20261022, the generator supplies 2,200 cycles. The established baseline
checks 1,329 read responses; confirm the actual summary for each run.
Reset clears the Python memory and pending-response state. The SV test compares
the DUT response-valid and, on response cycles, every data word to the oracle.

## Acceptance criteria and limits

- Compilation and simulation exit successfully; watchdogs do not expire.
- The modular scoreboard reports zero failures and the required summaries.
- The stress test has no valid/data mismatch or procedural CHECK FAIL.
- Current CI runs both layers and uploads logs as memory-evidence artifacts.
- Protocol counters reset with the DUT; their final summary describes the last
  reset epoch. The oracle's cycle/response totals describe the entire vector file.
- Coverage is scoped to the manually defined bins and directed/oracle scenarios.
  No complete DDR, UVM class-library, concurrent-SVA or exhaustive-coverage claim
  follows from these results.
- The modular legacy monitor is not a general outstanding-transaction scoreboard.
  Consecutive-read checking comes from the separate streaming oracle test.

See [README](README.md) and [dated upgrade evidence](proof/UPGRADE_VALIDATION.md).

## Regression-result integrity

The default generator emits 15 transactions, including eight reads. The modular
runner requires exactly one scoreboard summary with 15 passes / zero failures,
and one protocol summary with eight reads, eight responses and positive checked
cycles. It rejects empty, truncated, duplicated or contradictory summaries.
Update these explicit expectations if the directed generator contract changes.

Nine Python negative-control tests exercise the result parser. A separate CI
mutation suppresses both actual transaction-valid outputs in a temporary copy of
the monitor; simulation may exit zero and report FAIL=0, but the runner must
reject PASS=0. The normal DUT and monitor are not modified by the mutation test.

```bash
python3 -m unittest discover -s scripts -p 'test_regression_results.py' -v
python3 scripts/check_monitor_mutation.py
```

The independent streaming oracle remains a separate check of the real DUT.
