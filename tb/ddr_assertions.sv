`timescale 1ns/1ps

module ddr_assertions (
    input logic        clk,
    input logic        rst,

    input logic        req_valid,
    input logic        req_ready,
    input logic        req_write,
    input logic [7:0]  req_addr,
    input logic [31:0] req_wdata,

    input logic        resp_valid,
    input logic [31:0] resp_rdata
);

    logic   pending_read;
    integer read_latency;
    integer accepted_read_count;
    integer response_count;
    integer check_pass_count;
    integer check_fail_count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pending_read        <= 1'b0;
            read_latency        <= 0;
            accepted_read_count <= 0;
            response_count      <= 0;
            check_pass_count    <= 0;
            check_fail_count    <= 0;
        end else begin

            if (req_valid && req_ready) begin
                if (!$isunknown(req_addr)) begin
                    check_pass_count <= check_pass_count + 1;
                end else begin
                    check_fail_count <= check_fail_count + 1;
                    $error("CHECK FAIL: req_addr is X/Z during accepted request at time %0t", $time);
                end
            end

            if (req_valid && req_ready && !req_write) begin
                accepted_read_count <= accepted_read_count + 1;

                if (pending_read) begin
                    check_fail_count <= check_fail_count + 1;
                    $error("CHECK FAIL: new read accepted while previous read is pending at time %0t", $time);
                end

                pending_read <= 1'b1;
                read_latency <= 0;
            end else if (pending_read && !resp_valid) begin
                read_latency <= read_latency + 1;

                if (read_latency >= 4) begin
                    check_fail_count <= check_fail_count + 1;
                    $error("CHECK FAIL: resp_valid not seen within 1-4 cycles after accepted read at time %0t", $time);
                    pending_read <= 1'b0;
                    read_latency <= 0;
                end
            end

            if (resp_valid) begin
                response_count <= response_count + 1;

                if (!pending_read) begin
                    check_fail_count <= check_fail_count + 1;
                    $error("CHECK FAIL: resp_valid asserted without pending read at time %0t", $time);
                end else begin
                    check_pass_count <= check_pass_count + 1;
                end

                pending_read <= 1'b0;
                read_latency <= 0;
            end
        end
    end

    final begin
        $display("========================================");
        $display("DDR PROTOCOL CHECK SUMMARY");
        $display("READS=%0d RESPONSES=%0d PASS=%0d FAIL=%0d",
                 accepted_read_count, response_count, check_pass_count, check_fail_count);
        $display("========================================");
    end

endmodule
