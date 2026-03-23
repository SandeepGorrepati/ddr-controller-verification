`timescale 1ns/1ps

interface ddr_if(input logic clk);

    logic        rst;

    logic        req_valid;
    logic        req_write;
    logic [7:0]  req_addr;
    logic [31:0] req_wdata;
    logic        req_ready;

    logic        resp_valid;
    logic [31:0] resp_rdata;

endinterface
