`timescale 1ns/1ps

module ddr_controller (
    input  logic        clk,
    input  logic        rst,

    input  logic        req_valid,
    input  logic        req_write,
    input  logic [7:0]  req_addr,
    input  logic [31:0] req_wdata,
    output logic        req_ready,

    output logic        resp_valid,
    output logic [31:0] resp_rdata
);

    logic [31:0] mem [0:255];

    logic        read_pending;
    logic [7:0]  read_addr_q;

    integer i;

    assign req_ready = 1'b1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            resp_valid    <= 1'b0;
            resp_rdata    <= 32'h0;
            read_pending  <= 1'b0;
            read_addr_q   <= 8'h00;

            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 32'h0;
        end else begin
            resp_valid <= 1'b0;

            // Complete previously accepted read with fixed 1-cycle latency
            if (read_pending) begin
                resp_valid   <= 1'b1;
                resp_rdata   <= mem[read_addr_q];
                read_pending <= 1'b0;
            end

            // Accept new request
            if (req_valid && req_ready) begin
                if (req_write) begin
                    mem[req_addr] <= req_wdata;
                end else begin
                    read_pending <= 1'b1;
                    read_addr_q  <= req_addr;
                end
            end
        end
    end

endmodule
