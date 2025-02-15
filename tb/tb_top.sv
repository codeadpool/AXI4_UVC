`define TIME_PERIOD 10
`include "axi_if.sv"

module tb_top;
	import axi_test_pkg::*;
	import uvm_pkg::*;

	bit clk;
  initial forever #(`TIME_PERIOD/2) clk = ~clk;

	axi_if in0(clk);
  initial begin
    $dumpfile("axi_dump.vcd");
    $dumpvars(1);

    uvm_config_db#(virtual axi_if)::set(null, "", "vif", in0);
    run_test("axi_wbase_test");
  end
endmodule
