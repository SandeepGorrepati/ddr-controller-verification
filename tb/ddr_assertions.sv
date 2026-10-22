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

    // DUT accepts a read each cycle. At a sampling edge resp_valid reflects
    // the request from two sampling edges ago (one registered DUT cycle).
    logic accept_d1, accept_d2;
    integer accepted_read_count, response_count, check_pass_count, check_fail_count;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            accept_d1 <= 0; accept_d2 <= 0;
            accepted_read_count <= 0; response_count <= 0;
            check_pass_count <= 0; check_fail_count <= 0;
        end else begin
            accept_d1 <= req_valid && req_ready && !req_write;
            accept_d2 <= accept_d1;
            if(req_valid && req_ready) begin
                if($isunknown(req_addr) || $isunknown(req_write) ||
                   (req_write && $isunknown(req_wdata)))
                    $fatal(1,"CHECK FAIL: unknown accepted request");
            end
            if(resp_valid !== accept_d2) begin
                check_fail_count <= check_fail_count+1;
                $fatal(1,"CHECK FAIL: missing, spurious or late response");
            end
            if(resp_valid && $isunknown(resp_rdata))
                $fatal(1,"CHECK FAIL: unknown response data");
            if(req_valid && req_ready && !req_write)
                accepted_read_count <= accepted_read_count+1;
            if(resp_valid) response_count <= response_count+1;
            check_pass_count <= check_pass_count+1;
        end
    end
    final begin
        $display("DDR PROTOCOL CHECK SUMMARY");
        $display("READS=%0d RESPONSES=%0d PASS=%0d FAIL=%0d",
          accepted_read_count,response_count,check_pass_count,check_fail_count);
    end
endmodule
