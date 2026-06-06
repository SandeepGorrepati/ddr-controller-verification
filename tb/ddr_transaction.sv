`timescale 1ns/1ps

// Transaction object kept as UVM-inspired reusable stimulus model.
// The main Icarus regression uses generator.sv for simulator compatibility;
// this class documents the intended constrained-random transaction structure.
class ddr_transaction;
    rand bit        write;
    rand bit [7:0]  addr;
    rand bit [31:0] wdata;
         bit [31:0] rdata;

    constraint c_valid_addr  { addr inside {[8'h00:8'hFE]}; }
    constraint c_no_reserved { addr != 8'hFF; }
    constraint c_data_range  { wdata inside {[32'h0000_0001:32'hFFFF_FFFE]}; }

    function void display(string tag="TRANS");
        $display("[%s] write=%0d addr=0x%02h wdata=0x%08h rdata=0x%08h time=%0t",
                 tag, write, addr, wdata, rdata, $time);
    endfunction
endclass
