# DDR Controller Verification Environment (SystemVerilog)

## Overview
This project implements a self-checking SystemVerilog verification environment for a simplified DDR-style memory controller.

The environment verifies read/write behavior, response latency, overwrite handling, and correctness using a modular testbench architecture.

---

## Verification Architecture

Generator → Driver → DUT → Monitor → Scoreboard

### Components
- Generator: Produces directed read/write transactions
- Driver: Drives transactions into DUT interface
- Monitor: Observes DUT request/response behavior
- Scoreboard: Compares expected vs actual results
- DUT: Simplified DDR-style memory controller with 1-cycle read latency

---

## DUT Interface Signals

- req_valid
- req_ready
- req_write
- req_addr [7:0]
- req_wdata [31:0]
- resp_valid
- resp_rdata [31:0]

---

## Verification Scenarios

- Read from empty memory → returns 0x00000000
- Write to address 0x10 → read back 0x1234ABCD
- Write to address 0x20 → read back 0xDEADBEEF
- Overwrite address 0x20 → read back 0xCAFEBABE

---

## Simulation Result

Final self-checking result:

SCOREBOARD SUMMARY: PASS=7 FAIL=0

---

## Key Concepts Demonstrated

- Modular verification environment design
- Driver / Monitor / Scoreboard architecture
- Transaction-level verification
- Handling DUT read latency
- Scoreboard-based correctness checking

---

## Waveform Proof

### Read from Empty Memory
![Read Empty](screenshots/ddr_read_empty.png)

### Write Transaction
![Write](screenshots/ddr_write_transaction.png)

### Readback Verification
![Readback](screenshots/ddr_readback_verification.png)

### Overwrite and Final Readback
![Overwrite](screenshots/ddr_overwrite_readback.png)

---

## How to Run

iverilog -g2012 -Wall -o build/ddr_verif_env_modular.out \
rtl/ddr_controller.sv \
tb/ddr_if.sv \
tb/generator.sv \
tb/driver.sv \
tb/monitor.sv \
tb/scoreboard.sv \
tb/tb_top.sv

vvp build/ddr_verif_env_modular.out

gtkwave build/ddr_verif_env_modular.vcd

---

## Future Improvements

- Randomized transaction generation
- Functional coverage
- SystemVerilog Assertions (SVA)
- Corner-case testing

