`timescale 1ns/1ps

module monitor (
    input  logic        clk,
    input  logic        rst,

    input  logic        req_valid,
    input  logic        req_ready,
    input  logic        req_write,
    input  logic [7:0]  req_addr,
    input  logic [31:0] req_wdata,

    input  logic        resp_valid,
    input  logic [31:0] resp_rdata,

    output logic        act_valid,
    output logic        act_write,
    output logic [7:0]  act_addr,
    output logic [31:0] act_wdata,
    output logic [31:0] act_rdata
);

    logic       pending_read;
    logic [7:0] pending_addr;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            act_valid    <= 1'b0;
            act_write    <= 1'b0;
            act_addr     <= 8'h00;
            act_wdata    <= 32'h0000_0000;
            act_rdata    <= 32'h0000_0000;
            pending_read <= 1'b0;
            pending_addr <= 8'h00;
        end else begin
            act_valid <= 1'b0;

            if (req_valid && req_ready) begin
                if (req_write) begin
                    act_valid <= 1'b1;
                    act_write <= 1'b1;
                    act_addr  <= req_addr;
                    act_wdata <= req_wdata;
                    act_rdata <= 32'h0000_0000;

                    $display("[MONITOR][WRITE] addr=0x%02h data=0x%08h time=%0t",
                             req_addr, req_wdata, $time);
                end else begin
                    pending_read <= 1'b1;
                    pending_addr <= req_addr;
                end
            end

            if (resp_valid && pending_read) begin
                act_valid    <= 1'b1;
                act_write    <= 1'b0;
                act_addr     <= pending_addr;
                act_wdata    <= 32'h0000_0000;
                act_rdata    <= resp_rdata;
                pending_read <= 1'b0;

                $display("[MONITOR][READ] addr=0x%02h rdata=0x%08h time=%0t",
                         pending_addr, resp_rdata, $time);
            end
        end
    end

endmodule
