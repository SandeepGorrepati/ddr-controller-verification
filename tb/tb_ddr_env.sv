`timescale 1ns/1ps

module tb_ddr_env;

  logic        clk;
  logic        rst;

  // DUT request/response interface
  logic        req_valid;
  logic        req_write;
  logic [7:0]  req_addr;
  logic [31:0] req_wdata;
  logic        req_ready;

  logic        resp_valid;
  logic [31:0] resp_rdata;

  integer errors;
  integer i;

  // Coverage-style counters
  integer cov_write_count;
  integer cov_read_count;
  integer cov_low_addr;
  integer cov_mid_addr;
  integer cov_high_addr;
  integer cov_empty_read_count;
  integer cov_readback_hit_count;
  integer cov_overwrite_count;

  // Simple read-response timing checker
  logic [1:0] read_resp_countdown;

  // Transaction storage
  logic        txn_is_write [0:15];
  logic [7:0]  txn_addr     [0:15];
  logic [31:0] txn_data     [0:15];

  logic [31:0] exp_mem [0:255];
  logic [31:0] observed_data;

  // -----------------------------
  // DUT
  // -----------------------------
  ddr_controller dut (
      .clk(clk),
      .rst(rst),
      .req_valid(req_valid),
      .req_write(req_write),
      .req_addr(req_addr),
      .req_wdata(req_wdata),
      .req_ready(req_ready),
      .resp_valid(resp_valid),
      .resp_rdata(resp_rdata)
  );

  // -----------------------------
  // Clock
  // -----------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  // -----------------------------
  // Waveform dump
  // -----------------------------
  initial begin
    $dumpfile("build/ddr_verif_env.vcd");
    $dumpvars(0, tb_ddr_env);
  end

  // -----------------------------
  // Coverage-style scenario tracking
  // -----------------------------
  always @(posedge clk) begin
    if (!rst && req_valid && req_ready) begin
      if (req_write)
        cov_write_count = cov_write_count + 1;
      else
        cov_read_count = cov_read_count + 1;

      if (req_addr <= 8'h3F)
        cov_low_addr = cov_low_addr + 1;
      else if (req_addr <= 8'hBF)
        cov_mid_addr = cov_mid_addr + 1;
      else
        cov_high_addr = cov_high_addr + 1;
    end
  end

  // -----------------------------
  // Assertion-style protocol checks
  // -----------------------------
  // No response should appear during reset
  always @(posedge clk) begin
    if (rst && resp_valid) begin
      $display("ASSERTION FAIL: resp_valid high during reset at time %0t", $time);
      errors = errors + 1;
    end
  end

  // A read request should produce a response after the DUT's fixed latency
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      read_resp_countdown <= 2'd0;
    end else begin
      if (read_resp_countdown != 2'd0)
        read_resp_countdown <= read_resp_countdown - 1'b1;

      if (req_valid && req_ready && !req_write)
        read_resp_countdown <= 2'd2;

      if (read_resp_countdown == 2'd1 && !resp_valid) begin
        $display("ASSERTION FAIL: expected resp_valid after read request at time %0t", $time);
        errors = errors + 1;
      end
    end
  end

  // -----------------------------
  // Generator
  // -----------------------------
  task generator;
    begin
      $display("GENERATOR : creating transactions");

      // Directed tests
      txn_is_write[0] = 1'b0; txn_addr[0] = 8'h30; txn_data[0] = 32'h00000000; // empty read
      txn_is_write[1] = 1'b1; txn_addr[1] = 8'h10; txn_data[1] = 32'h1234ABCD;
      txn_is_write[2] = 1'b0; txn_addr[2] = 8'h10; txn_data[2] = 32'h1234ABCD;
      txn_is_write[3] = 1'b1; txn_addr[3] = 8'h20; txn_data[3] = 32'hDEADBEEF;
      txn_is_write[4] = 1'b0; txn_addr[4] = 8'h20; txn_data[4] = 32'hDEADBEEF;
      txn_is_write[5] = 1'b1; txn_addr[5] = 8'h10; txn_data[5] = 32'hCAFEBABE; // overwrite
      txn_is_write[6] = 1'b0; txn_addr[6] = 8'h10; txn_data[6] = 32'hCAFEBABE;

      // Randomized write/read pairs
      for (i = 7; i < 15; i = i + 2) begin
        txn_is_write[i]   = 1'b1;
        txn_addr[i]       = $random;
        txn_data[i]       = $random;

        txn_is_write[i+1] = 1'b0;
        txn_addr[i+1]     = txn_addr[i];
        txn_data[i+1]     = txn_data[i];
      end
    end
  endtask

  // -----------------------------
  // Driver
  // -----------------------------
  task driver(
      input logic        is_write,
      input logic [7:0]  t_addr,
      input logic [31:0] t_data
  );
    begin
      @(posedge clk);

      req_addr  <= t_addr;
      req_wdata <= t_data;
      req_write <= is_write;
      req_valid <= 1'b1;

      if (is_write)
        $display("DRIVER    : WRITE addr=%h data=%h time=%0t", t_addr, t_data, $time);
      else
        $display("DRIVER    : READ  addr=%h exp=%h time=%0t", t_addr, t_data, $time);

      @(posedge clk);
      req_valid <= 1'b0;
      req_write <= 1'b0;
      req_addr  <= 8'h00;
      req_wdata <= 32'h00000000;
    end
  endtask

  // -----------------------------
  // Monitor
  // -----------------------------
  task monitor(
      input logic         is_write,
      input logic [7:0]   t_addr,
      input logic [31:0]  t_data,
      output logic [31:0] observed
  );
    begin
      observed = 32'h00000000;

      if (is_write) begin
        observed = t_data;
        $display("MONITOR   : WRITE observed addr=%h data=%h time=%0t", t_addr, t_data, $time);
      end
      else begin
        @(posedge clk);
        wait (resp_valid == 1'b1);
        observed = resp_rdata;
        $display("MONITOR   : READ  observed addr=%h data=%h time=%0t", t_addr, observed, $time);
      end
    end
  endtask

  // -----------------------------
  // Scoreboard
  // -----------------------------
  task scoreboard(
      input logic        is_write,
      input logic [7:0]  t_addr,
      input logic [31:0] t_data,
      input logic [31:0] observed
  );
    logic [31:0] expected;
    begin
      if (is_write) begin
        if (exp_mem[t_addr] !== 32'h00000000)
          cov_overwrite_count = cov_overwrite_count + 1;

        exp_mem[t_addr] = t_data;
        $display("SCOREBOARD: WRITE recorded addr=%h data=%h", t_addr, t_data);
      end
      else begin
        expected = exp_mem[t_addr];

        if (expected == 32'h00000000)
          cov_empty_read_count = cov_empty_read_count + 1;
        else
          cov_readback_hit_count = cov_readback_hit_count + 1;

        if (observed !== expected) begin
          $display("SCOREBOARD: FAIL addr=%h expected=%h got=%h", t_addr, expected, observed);
          errors = errors + 1;
        end
        else begin
          $display("SCOREBOARD: PASS addr=%h expected=%h got=%h", t_addr, expected, observed);
        end
      end
    end
  endtask

  // -----------------------------
  // Test flow
  // -----------------------------
  initial begin
    rst                  = 1'b1;
    req_valid            = 1'b0;
    req_write            = 1'b0;
    req_addr             = 8'h00;
    req_wdata            = 32'h00000000;
    errors               = 0;

    cov_write_count      = 0;
    cov_read_count       = 0;
    cov_low_addr         = 0;
    cov_mid_addr         = 0;
    cov_high_addr        = 0;
    cov_empty_read_count = 0;
    cov_readback_hit_count = 0;
    cov_overwrite_count  = 0;

    read_resp_countdown  = 2'd0;

    for (i = 0; i < 256; i = i + 1)
      exp_mem[i] = 32'h00000000;

    $display("SIM START: Structured DDR Verification Environment");

    // Reset
    repeat (2) @(posedge clk);
    rst = 1'b0;

    // Generate transactions
    generator();

    // Apply, monitor, check
    for (i = 0; i < 15; i = i + 1) begin
      driver(txn_is_write[i], txn_addr[i], txn_data[i]);
      monitor(txn_is_write[i], txn_addr[i], txn_data[i], observed_data);
      scoreboard(txn_is_write[i], txn_addr[i], txn_data[i], observed_data);
    end

    $display("COVERAGE SUMMARY: writes=%0d reads=%0d low_addr=%0d mid_addr=%0d high_addr=%0d empty_reads=%0d readbacks=%0d overwrites=%0d",
             cov_write_count, cov_read_count, cov_low_addr, cov_mid_addr, cov_high_addr,
             cov_empty_read_count, cov_readback_hit_count, cov_overwrite_count);

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("TESTS FAILED: errors=%0d", errors);

    #20;
    $finish;
  end

endmodule
