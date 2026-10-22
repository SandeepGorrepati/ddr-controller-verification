`timescale 1ns/1ps
module tb_stress;
  reg clk=0,rst=1,req_valid=0,req_write=0;
  always #5 clk=~clk;
  reg [7:0] req_addr=0;
  reg [31:0] req_wdata=0;
  wire req_ready,resp_valid;
  wire [31:0] resp_rdata;
  ddr_controller dut(.*);
  ddr_assertions checker_i(.*);
  integer f,rc,rs,v,w,ev,cycles=0,reads=0;
  reg [31:0] ed;
  initial begin
    f=$fopen("build/stress.txt","r");
    if(!f) $fatal(1,"oracle missing");
    while(!$feof(f)) begin
      @(negedge clk);
      rc=$fscanf(f,"%h %h %h %h %h %h %h\n",rs,v,w,req_addr,req_wdata,ev,ed);
      if(rc != 7) $fatal(1,"bad oracle row");
      rst=rs[0]; req_valid=v[0]; req_write=w[0];
      @(posedge clk); #1;
      if(req_ready !== 1) $fatal(1,"unexpected backpressure");
      if(resp_valid !== ev[0]) $fatal(1,"response latency cycle=%0d",cycles);
      if(ev) begin
        if(resp_rdata !== ed) $fatal(1,"data cycle=%0d got=%h exp=%h",cycles,resp_rdata,ed);
        reads=reads+1;
      end
      cycles=cycles+1;
    end
    $display("PASS: memory oracle cycles=%0d responses=%0d; pipelined reads, mixed writes, reset",cycles,reads);
    $finish;
  end
  initial begin #100000; $fatal(1,"stress timeout"); end
endmodule
