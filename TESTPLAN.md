# DDR Controller Verification Test Plan

## Objective
Verify a simplified DDR-style memory controller using a modular SystemVerilog environment with generator, driver, monitor, scoreboard, SVA protocol checks, functional coverage tracking, and regression logs.

## DUT Interface
| Signal | Direction | Description |
|---|---|---|
| `req_valid` | input | Request valid from driver |
| `req_ready` | output | DUT ready to accept request |
| `req_write` | input | 1 = write, 0 = read |
| `req_addr[7:0]` | input | 256-entry memory address |
| `req_wdata[31:0]` | input | Write data |
| `resp_valid` | output | Read response valid |
| `resp_rdata[31:0]` | output | Read response data |

## Verification Architecture
`generator -> driver -> DUT -> monitor -> scoreboard`

Additional checkers:
- `ddr_assertions.sv`: SVA protocol checks
- `coverage_tracker.sv`: operation/address/cross coverage counters
- `scripts/run_regression.py`: compile/run/log regression flow

## Test Scenarios
| ID | Scenario | Expected Result |
|---|---|---|
| T1 | Read empty address | Returns `0x00000000` |
| T2 | Write address `0x10` | Scoreboard records expected memory data |
| T3 | Read back address `0x10` | Returns written data |
| T4 | Write address `0x20` | Scoreboard records expected memory data |
| T5 | Read back address `0x20` | Returns written data |
| T6 | Overwrite address `0x20` | Scoreboard updates expected data |
| T7 | Read back overwritten address | Returns latest written data |
| T8-T15 | Constrained randomized write/read pairs | Readback matches randomized write data |

## SVA Checks
| Assertion | Intent |
|---|---|
| `p_read_response_within_4_cycles` | Accepted read request must produce `resp_valid` within 1-4 cycles |
| `p_no_spurious_response` | `resp_valid` must not appear without a pending read |
| `p_known_addr_on_accept` | Accepted request address must not be X/Z |

## Functional Coverage Tracking
| Coverage bin | Intent |
|---|---|
| Operation bins | Count read and write transactions |
| Address range bins | Count low/mid/high address-range activity |
| Response bin | Count observed read responses |
| Cross bins | Count read/write distribution across address ranges |

## Pass Criteria
- Scoreboard summary reports `FAIL=0`
- No `SVA FAIL` or `ASSERTION FAIL` messages appear
- Functional coverage summary is printed
- Regression log is saved in `proof/ddr_regression.log`

## Run Command
```bash
python3 scripts/run_regression.py
```
