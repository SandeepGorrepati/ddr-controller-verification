`timescale 1ns/1ps

// Icarus-friendly functional coverage tracker using explicit bins/counters.
// This complements the scoreboard and prints operation/address/cross coverage.
module coverage_tracker (
    input logic       clk,
    input logic       rst,

    input logic       req_valid,
    input logic       req_ready,
    input logic       req_write,
    input logic [7:0] req_addr,
    input logic       resp_valid,

    input logic       done
);

    integer write_count;
    integer read_count;
    integer low_addr_count;
    integer mid_addr_count;
    integer high_addr_count;
    integer resp_seen_count;

    integer write_low_count;
    integer write_mid_count;
    integer write_high_count;
    integer read_low_count;
    integer read_mid_count;
    integer read_high_count;

    integer summary_delay;
    logic   summary_printed;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            write_count     <= 0;
            read_count      <= 0;
            low_addr_count  <= 0;
            mid_addr_count  <= 0;
            high_addr_count <= 0;
            resp_seen_count <= 0;

            write_low_count  <= 0;
            write_mid_count  <= 0;
            write_high_count <= 0;
            read_low_count   <= 0;
            read_mid_count   <= 0;
            read_high_count  <= 0;

            summary_delay   <= 0;
            summary_printed <= 1'b0;
        end else begin
            if (req_valid && req_ready) begin
                if (req_write)
                    write_count <= write_count + 1;
                else
                    read_count <= read_count + 1;

                if (req_addr <= 8'h3F) begin
                    low_addr_count <= low_addr_count + 1;
                    if (req_write) write_low_count <= write_low_count + 1;
                    else           read_low_count  <= read_low_count + 1;
                end else if (req_addr <= 8'h7F) begin
                    mid_addr_count <= mid_addr_count + 1;
                    if (req_write) write_mid_count <= write_mid_count + 1;
                    else           read_mid_count  <= read_mid_count + 1;
                end else begin
                    high_addr_count <= high_addr_count + 1;
                    if (req_write) write_high_count <= write_high_count + 1;
                    else           read_high_count  <= read_high_count + 1;
                end
            end

            if (resp_valid)
                resp_seen_count <= resp_seen_count + 1;

            if (done && !summary_printed) begin
                if (summary_delay < 12) begin
                    summary_delay <= summary_delay + 1;
                end else begin
                    $display("========================================");
                    $display("FUNCTIONAL COVERAGE SUMMARY");
                    $display("Operation bins       : writes=%0d reads=%0d", write_count, read_count);
                    $display("Address range bins   : low=%0d mid=%0d high=%0d", low_addr_count, mid_addr_count, high_addr_count);
                    $display("Response bins        : resp_seen=%0d", resp_seen_count);
                    $display("Cross op x addr bins : W_LOW=%0d W_MID=%0d W_HIGH=%0d R_LOW=%0d R_MID=%0d R_HIGH=%0d",
                             write_low_count, write_mid_count, write_high_count,
                             read_low_count, read_mid_count, read_high_count);
                    $display("========================================");
                    summary_printed <= 1'b1;
                end
            end
        end
    end

endmodule
