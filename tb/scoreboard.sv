`timescale 1ns/1ps

module scoreboard (
    input  logic        clk,
    input  logic        rst,

    input  logic        exp_valid,
    input  logic        exp_write,
    input  logic [7:0]  exp_addr,
    input  logic [31:0] exp_wdata,

    input  logic        act_valid,
    input  logic        act_write,
    input  logic [7:0]  act_addr,
    input  logic [31:0] act_wdata,
    input  logic [31:0] act_rdata,

    input  logic        done
);

    logic [31:0] ref_mem [0:255];

    logic        last_exp_valid;
    logic        last_exp_write;
    logic [7:0]  last_exp_addr;
    logic [31:0] last_exp_wdata;

    logic        pending_read;
    logic [7:0]  pending_read_addr;
    logic [31:0] pending_read_exp;

    logic        summary_printed;

    integer pass_count;
    integer fail_count;
    integer summary_delay;
    integer i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pass_count         <= 0;
            fail_count         <= 0;

            last_exp_valid     <= 1'b0;
            last_exp_write     <= 1'b0;
            last_exp_addr      <= 8'h00;
            last_exp_wdata     <= 32'h0000_0000;

            pending_read       <= 1'b0;
            pending_read_addr  <= 8'h00;
            pending_read_exp   <= 32'h0000_0000;

            summary_printed    <= 1'b0;
            summary_delay      <= 0;

            for (i = 0; i < 256; i = i + 1)
                ref_mem[i] <= 32'h0000_0000;
        end else begin
            // Capture expected transaction from driver side
            if (exp_valid) begin
                last_exp_valid <= 1'b1;
                last_exp_write <= exp_write;
                last_exp_addr  <= exp_addr;
                last_exp_wdata <= exp_wdata;

                if (exp_write) begin
                    ref_mem[exp_addr] <= exp_wdata;
                end else begin
                    pending_read      <= 1'b1;
                    pending_read_addr <= exp_addr;
                    pending_read_exp  <= ref_mem[exp_addr];
                end
            end

            // Compare observed transaction from monitor side
            if (act_valid) begin
                if (act_write) begin
                    if (last_exp_valid && last_exp_write &&
                        act_addr  == last_exp_addr &&
                        act_wdata == last_exp_wdata) begin
                        $display("[SCB][PASS][WRITE] addr=0x%02h data=0x%08h time=%0t",
                                 act_addr, act_wdata, $time);
                        pass_count <= pass_count + 1;
                    end else begin
                        $display("[SCB][FAIL][WRITE] exp_addr=0x%02h exp_data=0x%08h act_addr=0x%02h act_data=0x%08h time=%0t",
                                 last_exp_addr, last_exp_wdata, act_addr, act_wdata, $time);
                        fail_count <= fail_count + 1;
                    end
                    last_exp_valid <= 1'b0;
                end else begin
                    if (pending_read &&
                        act_addr  == pending_read_addr &&
                        act_rdata == pending_read_exp) begin
                        $display("[SCB][PASS][READ] addr=0x%02h exp=0x%08h act=0x%08h time=%0t",
                                 act_addr, pending_read_exp, act_rdata, $time);
                        pass_count <= pass_count + 1;
                    end else begin
                        $display("[SCB][FAIL][READ] exp_addr=0x%02h exp_data=0x%08h act_addr=0x%02h act_data=0x%08h time=%0t",
                                 pending_read_addr, pending_read_exp, act_addr, act_rdata, $time);
                        fail_count <= fail_count + 1;
                    end
                    pending_read <= 1'b0;
                end
            end

            // Delay summary so final read is included
            if (done && !summary_printed) begin
                if (summary_delay < 8) begin
                    summary_delay <= summary_delay + 1;
                end else begin
                    $display("========================================");
                    $display("SCOREBOARD SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
                    $display("========================================");
                    summary_printed <= 1'b1;
                end
            end
        end
    end

endmodule
