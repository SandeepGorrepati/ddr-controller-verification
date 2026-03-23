`timescale 1ns/1ps

class ddr_transaction;
    rand bit        write;
    rand bit [7:0]  addr;
    rand bit [31:0] wdata;
         bit [31:0] rdata;

    function void display(string tag="TRANS");
        $display("[%s] write=%0d addr=0x%02h wdata=0x%08h rdata=0x%08h time=%0t",
                 tag, write, addr, wdata, rdata, $time);
    endfunction
endclass
