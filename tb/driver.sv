`timescale 1ns/1ps

module driver (
    input  logic        clk,
    input  logic        rst,

    input  logic        tr_valid,
    input  logic        tr_write,
    input  logic [7:0]  tr_addr,
    input  logic [31:0] tr_wdata,
    output logic        tr_ready,

    output logic        req_valid,
    output logic        req_write,
    output logic [7:0]  req_addr,
    output logic [31:0] req_wdata,
    input  logic        req_ready,

    output logic        exp_valid,
    output logic        exp_write,
    output logic [7:0]  exp_addr,
    output logic [31:0] exp_wdata
);

    assign tr_ready = req_ready;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            req_valid <= 1'b0;
            req_write <= 1'b0;
            req_addr  <= 8'h00;
            req_wdata <= 32'h0000_0000;

            exp_valid <= 1'b0;
            exp_write <= 1'b0;
            exp_addr  <= 8'h00;
            exp_wdata <= 32'h0000_0000;
        end else begin
            exp_valid <= 1'b0;

            if (tr_valid && req_ready) begin
                req_valid <= 1'b1;
                req_write <= tr_write;
                req_addr  <= tr_addr;
                req_wdata <= tr_wdata;

                exp_valid <= 1'b1;
                exp_write <= tr_write;
                exp_addr  <= tr_addr;
                exp_wdata <= tr_wdata;

                $display("[DRIVER] write=%0d addr=0x%02h wdata=0x%08h time=%0t",
                         tr_write, tr_addr, tr_wdata, $time);
            end else begin
                req_valid <= 1'b0;
                req_write <= 1'b0;
                req_addr  <= 8'h00;
                req_wdata <= 32'h0000_0000;
            end
        end
    end

endmodule
