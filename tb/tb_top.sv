`timescale 1ns/1ps

module tb_top;

    logic clk;
    ddr_if vif(clk);

    logic        tr_valid;
    logic        tr_write;
    logic [7:0]  tr_addr;
    logic [31:0] tr_wdata;
    logic        tr_ready;
    logic        done;

    logic        exp_valid;
    logic        exp_write;
    logic [7:0]  exp_addr;
    logic [31:0] exp_wdata;

    logic        act_valid;
    logic        act_write;
    logic [7:0]  act_addr;
    logic [31:0] act_wdata;
    logic [31:0] act_rdata;

    ddr_controller dut (
        .clk       (clk),
        .rst       (vif.rst),
        .req_valid (vif.req_valid),
        .req_write (vif.req_write),
        .req_addr  (vif.req_addr),
        .req_wdata (vif.req_wdata),
        .req_ready (vif.req_ready),
        .resp_valid(vif.resp_valid),
        .resp_rdata(vif.resp_rdata)
    );

    generator u_gen (
        .clk      (clk),
        .rst      (vif.rst),
        .tr_valid (tr_valid),
        .tr_write (tr_write),
        .tr_addr  (tr_addr),
        .tr_wdata (tr_wdata),
        .tr_ready (tr_ready),
        .done     (done)
    );

    driver u_drv (
        .clk      (clk),
        .rst      (vif.rst),
        .tr_valid (tr_valid),
        .tr_write (tr_write),
        .tr_addr  (tr_addr),
        .tr_wdata (tr_wdata),
        .tr_ready (tr_ready),
        .req_valid(vif.req_valid),
        .req_write(vif.req_write),
        .req_addr (vif.req_addr),
        .req_wdata(vif.req_wdata),
        .req_ready(vif.req_ready),
        .exp_valid(exp_valid),
        .exp_write(exp_write),
        .exp_addr (exp_addr),
        .exp_wdata(exp_wdata)
    );

    monitor u_mon (
        .clk      (clk),
        .rst      (vif.rst),
        .req_valid(vif.req_valid),
        .req_ready(vif.req_ready),
        .req_write(vif.req_write),
        .req_addr (vif.req_addr),
        .req_wdata(vif.req_wdata),
        .resp_valid(vif.resp_valid),
        .resp_rdata(vif.resp_rdata),
        .act_valid(act_valid),
        .act_write(act_write),
        .act_addr (act_addr),
        .act_wdata(act_wdata),
        .act_rdata(act_rdata)
    );

    scoreboard u_scb (
        .clk      (clk),
        .rst      (vif.rst),
        .exp_valid(exp_valid),
        .exp_write(exp_write),
        .exp_addr (exp_addr),
        .exp_wdata(exp_wdata),
        .act_valid(act_valid),
        .act_write(act_write),
        .act_addr (act_addr),
        .act_wdata(act_wdata),
        .act_rdata(act_rdata),
        .done     (done)
    );


    ddr_assertions u_assertions (
        .clk       (clk),
        .rst       (vif.rst),
        .req_valid (vif.req_valid),
        .req_ready (vif.req_ready),
        .req_write (vif.req_write),
        .req_addr  (vif.req_addr),
        .req_wdata (vif.req_wdata),
        .resp_valid(vif.resp_valid),
        .resp_rdata(vif.resp_rdata)
    );

    coverage_tracker u_cov (
        .clk       (clk),
        .rst       (vif.rst),
        .req_valid (vif.req_valid),
        .req_ready (vif.req_ready),
        .req_write (vif.req_write),
        .req_addr  (vif.req_addr),
        .resp_valid(vif.resp_valid),
        .done      (done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("build/ddr_verif_env_modular.vcd");
        $dumpvars(0, tb_top);

        vif.rst = 1'b1;
        #20;
        vif.rst = 1'b0;

        #800;
        $finish;
    end

endmodule
