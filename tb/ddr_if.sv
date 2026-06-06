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

    modport driver_mp (
        output req_valid,
        output req_write,
        output req_addr,
        output req_wdata,
        input  req_ready,
        input  resp_valid,
        input  resp_rdata
    );

    modport monitor_mp (
        input req_valid,
        input req_write,
        input req_addr,
        input req_wdata,
        input req_ready,
        input resp_valid,
        input resp_rdata
    );

    modport dut_mp (
        input  rst,
        input  req_valid,
        input  req_write,
        input  req_addr,
        input  req_wdata,
        output req_ready,
        output resp_valid,
        output resp_rdata
    );

endinterface
