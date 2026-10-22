# Request/response memory-controller verification

![Memory regression](https://github.com/SandeepGorrepati/ddr-controller-verification/actions/workflows/regression.yml/badge.svg)
![RTL lint](https://github.com/SandeepGorrepati/ddr-controller-verification/actions/workflows/lint.yml/badge.svg)

A self-checking SystemVerilog environment for a 256x32 request/response memory. The repository keeps its historical name, but the implemented DUT is not a DDR4 controller or PHY. It has no DRAM banks, ACT/PRE commands, refresh, bursts, or DDR timing parameters. The modular environment is UVM-inspired, not an implementation of the UVM class library.

## Contract

- Requests are accepted every cycle (`req_ready=1`). Addresses select words 0..255.
- Accepted writes update memory; they do not produce responses.
- Accepted reads produce a response one clock later and may arrive on consecutive cycles.
- A response observes memory before a write on that same completion edge (read-before-write semantics).
- Asynchronous active-high reset clears memory and cancels outstanding reads.
- There is no response backpressure, reordering, or multiple response IDs.

## Reproduce for free

Install Python 3 and Icarus Verilog, then run from the root:

```bash
python3 scripts/run_regression.py
python3 scripts/gen_stress.py
iverilog -g2012 -s tb_stress -o build/stress rtl/ddr_controller.sv tb/ddr_assertions.sv tb/tb_stress.sv
vvp build/stress
```

CI runs both flows and saves logs as artifacts. Compilation, simulator failures, checker errors, missing summaries, and timeouts fail the job.

## Verification evidence

| Environment | Result |
|---|---|
| Modular directed scoreboard | 15 passes, zero failures |
| Updated directed protocol checker | Eight reads/eight responses; 80 checked cycles, zero failures |
| Python cycle oracle | 2,200 traffic cycles; 1,329 read responses compared |

The stress flow covers pipelined reads, mixed reads/writes, repeated/boundary addresses, idle cycles, and reset during traffic. The independent Python model generates the response-valid/data expectation for every cycle; the SV test compares the real DUT against those vectors.

The protocol checker was corrected to support consecutive reads rather than flagging every new read while an earlier one remained pending. It now checks the exact registered latency, unknown request/data values, and missing/spurious responses. These are procedural assertions executed by Icarus; they are not concurrent SVA property declarations. Protocol counters reset with the DUT, so the final checker summary covers the last reset epoch; the stress test's response total spans the complete vector file.

The earlier committed log's 23 protocol checks are historical. They were never 23 scoreboard transactions. New protocol-check counts have a different definition and should not be compared as a coverage gain.

## Limits

The legacy modular generator/monitor/scoreboard demonstrates serialized directed verification. The separate oracle-based streaming test provides consecutive-read coverage; the legacy monitor is not claimed to be a general outstanding-transaction scoreboard. Manual coverage bins are scoped to their definitions. A real DDR command/timing model would be a separate extension requiring explicit implementation and verification.

See [upgrade validation](proof/UPGRADE_VALIDATION.md).
