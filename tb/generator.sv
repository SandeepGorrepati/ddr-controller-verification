`timescale 1ns/1ps

module generator (
    input  logic        clk,
    input  logic        rst,
    output logic        tr_valid,
    output logic        tr_write,
    output logic [7:0]  tr_addr,
    output logic [31:0] tr_wdata,
    input  logic        tr_ready,
    output logic        done
);

    logic [2:0] idx;
    logic       gap;

    function automatic logic seq_write(input logic [2:0] i);
        case (i)
            3'd0: seq_write = 1'b0;
            3'd1: seq_write = 1'b1;
            3'd2: seq_write = 1'b0;
            3'd3: seq_write = 1'b1;
            3'd4: seq_write = 1'b0;
            3'd5: seq_write = 1'b1;
            3'd6: seq_write = 1'b0;
            default: seq_write = 1'b0;
        endcase
    endfunction

    function automatic [7:0] seq_addr(input logic [2:0] i);
        case (i)
            3'd0: seq_addr = 8'h10;
            3'd1: seq_addr = 8'h10;
            3'd2: seq_addr = 8'h10;
            3'd3: seq_addr = 8'h20;
            3'd4: seq_addr = 8'h20;
            3'd5: seq_addr = 8'h20;
            3'd6: seq_addr = 8'h20;
            default: seq_addr = 8'h00;
        endcase
    endfunction

    function automatic [31:0] seq_wdata(input logic [2:0] i);
        case (i)
            3'd0: seq_wdata = 32'h0000_0000;
            3'd1: seq_wdata = 32'h1234_ABCD;
            3'd2: seq_wdata = 32'h0000_0000;
            3'd3: seq_wdata = 32'hDEAD_BEEF;
            3'd4: seq_wdata = 32'h0000_0000;
            3'd5: seq_wdata = 32'hCAFE_BABE;
            3'd6: seq_wdata = 32'h0000_0000;
            default: seq_wdata = 32'h0000_0000;
        endcase
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            idx      <= 3'd0;
            gap      <= 1'b0;
            tr_valid <= 1'b0;
            tr_write <= 1'b0;
            tr_addr  <= 8'h00;
            tr_wdata <= 32'h0000_0000;
            done     <= 1'b0;
        end else begin
            if (done) begin
                tr_valid <= 1'b0;
            end else if (tr_valid && tr_ready) begin
                tr_valid <= 1'b0;
                gap      <= 1'b1;

                if (idx == 3'd6)
                    done <= 1'b1;
                else
                    idx <= idx + 3'd1;
            end else if (gap) begin
                gap <= 1'b0;
            end else if (!tr_valid) begin
                tr_valid <= 1'b1;
                tr_write <= seq_write(idx);
                tr_addr  <= seq_addr(idx);
                tr_wdata <= seq_wdata(idx);
            end
        end
    end

endmodule
