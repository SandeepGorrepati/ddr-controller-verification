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

    localparam int NUM_TXNS = 15;

    logic [3:0] idx;
    logic       gap;

    logic [7:0]  rand_addr  [0:3];
    logic [31:0] rand_wdata [0:3];
    integer seed;

    function automatic [7:0] constrain_addr(input integer raw, input logic [1:0] bucket);
        logic [7:0] value;
        begin
            case (bucket)
                2'd0: value = {2'b00, raw[5:0]};      // 0x00-0x3F
                2'd1: value = {2'b01, raw[5:0]};      // 0x40-0x7F
                2'd2: value = {1'b1,  raw[6:0]};      // 0x80-0xFF
                default: value = raw[7:0];
            endcase

            if (value == 8'hFF)
                constrain_addr = 8'hFE;
            else
                constrain_addr = value;
        end
    endfunction

    function automatic [31:0] constrain_wdata(input integer raw);
        logic [31:0] value;
        begin
            value = {raw[15:0], ~raw[15:0]};
            if (value == 32'h0000_0000)
                constrain_wdata = 32'h0000_0001;
            else if (value == 32'hFFFF_FFFF)
                constrain_wdata = 32'hFFFF_FFFE;
            else
                constrain_wdata = value;
        end
    endfunction

    initial begin
        seed = 32'hD00D_2026;

        rand_addr[0]  = constrain_addr($random(seed), 2'd0);
        rand_wdata[0] = constrain_wdata($random(seed));

        rand_addr[1]  = constrain_addr($random(seed), 2'd1);
        rand_wdata[1] = constrain_wdata($random(seed));

        rand_addr[2]  = constrain_addr($random(seed), 2'd2);
        rand_wdata[2] = constrain_wdata($random(seed));

        rand_addr[3]  = constrain_addr($random(seed), 2'd3);
        rand_wdata[3] = constrain_wdata($random(seed));
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            idx      <= 4'd0;
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

                if (idx == NUM_TXNS-1)
                    done <= 1'b1;
                else
                    idx <= idx + 4'd1;
            end else if (gap) begin
                gap <= 1'b0;
            end else if (!tr_valid) begin
                tr_valid <= 1'b1;

                case (idx)
                    // Directed scenarios: empty read, write/readback, overwrite/readback
                    4'd0: begin tr_write <= 1'b0; tr_addr <= 8'h30; tr_wdata <= 32'h0000_0000; end
                    4'd1: begin tr_write <= 1'b1; tr_addr <= 8'h10; tr_wdata <= 32'h1234_ABCD; end
                    4'd2: begin tr_write <= 1'b0; tr_addr <= 8'h10; tr_wdata <= 32'h0000_0000; end
                    4'd3: begin tr_write <= 1'b1; tr_addr <= 8'h20; tr_wdata <= 32'hDEAD_BEEF; end
                    4'd4: begin tr_write <= 1'b0; tr_addr <= 8'h20; tr_wdata <= 32'h0000_0000; end
                    4'd5: begin tr_write <= 1'b1; tr_addr <= 8'h20; tr_wdata <= 32'hCAFE_BABE; end
                    4'd6: begin tr_write <= 1'b0; tr_addr <= 8'h20; tr_wdata <= 32'h0000_0000; end

                    // Constrained randomized write/read pairs
                    4'd7:  begin tr_write <= 1'b1; tr_addr <= rand_addr[0]; tr_wdata <= rand_wdata[0]; end
                    4'd8:  begin tr_write <= 1'b0; tr_addr <= rand_addr[0]; tr_wdata <= 32'h0000_0000; end
                    4'd9:  begin tr_write <= 1'b1; tr_addr <= rand_addr[1]; tr_wdata <= rand_wdata[1]; end
                    4'd10: begin tr_write <= 1'b0; tr_addr <= rand_addr[1]; tr_wdata <= 32'h0000_0000; end
                    4'd11: begin tr_write <= 1'b1; tr_addr <= rand_addr[2]; tr_wdata <= rand_wdata[2]; end
                    4'd12: begin tr_write <= 1'b0; tr_addr <= rand_addr[2]; tr_wdata <= 32'h0000_0000; end
                    4'd13: begin tr_write <= 1'b1; tr_addr <= rand_addr[3]; tr_wdata <= rand_wdata[3]; end
                    4'd14: begin tr_write <= 1'b0; tr_addr <= rand_addr[3]; tr_wdata <= 32'h0000_0000; end

                    default: begin tr_write <= 1'b0; tr_addr <= 8'h00; tr_wdata <= 32'h0000_0000; end
                endcase
            end
        end
    end

endmodule
