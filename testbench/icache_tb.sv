`include "cache_control_if.vh"
`include "datapath_cache_if.vh"
`include "cpu_ram_if.vh"


`timescale 1 ns / 1 ns




module icache_tb;
   cache_control_if ccif();
   datapath_cache_if dcif();
   cpu_ram_if ramif();
   

   // test vars
   logic CLK = 0;
   logic nRST;
   parameter PERIOD = 10;

   
   test PROG(CLK, nRST, dcif, ccif);
   icache DUT(CLK, nRST, dcif, ccif);
   memory_control MC(CLK, nRST, ccif);
   ram RAM(CLK, nRST, ramif);

   always #(PERIOD/2) CLK++;
   
   assign ccif.ramstate = ramif.ramstate;
   assign ccif.ramload = ramif.ramload;
   assign ramif.ramWEN = ccif.ramWEN;
   assign ramif.ramstore = ccif.ramstore;
   assign ramif.ramREN = ccif.ramREN;
   assign ramif.ramaddr = ccif.ramaddr;

endmodule // icache_tb

program test (
	      input logic CLK,
	      output logic nRST,
	      datapath_cache_if.dp dcif,
	      cache_control_if.cc ccif
	      );

   import cpu_types_pkg::*;
   parameter PERIOD = 10;
   icachef_t addr;
   
   // test cases
   initial
     begin
	int testnum;

	$display("\n\n******* START OF TESTS *******\n");

	// initial reset
	nRST = 1'b0;
	#(PERIOD*2);
	nRST = 1'b1;
	#(PERIOD*2);

	// write instrs to ram for cach misses
	// ccif.iaddr = 0;
	// ccif.iREN = 0;
	@(posedge CLK);
	ccif.iaddr = 0;
	ccif.iREN = 0;
	ccif.dWEN = 1;
	ccif.dREN = 0;
	ccif.dstore = 32'hDEADBEEF;
	ccif.daddr = 32'd1000;
	#(PERIOD*2);

	ccif.dWEN = 0;

	// let icache state machine return to idle
	#(PERIOD*4);
 
	// TEST 1: first address, cache miss
	testnum++;
	addr = 32'd1000; // 1111 101000 in binary (idx = 1111)
	dcif.imemREN = 1'b1;
	dcif.imemaddr = 32'd1000;
	#(PERIOD*2);
	if (!dcif.ihit) // dcif.imemload == 32'hDEADBEEF)
          $display("TEST %2d passed", testnum);
	else 
	  $display("TEST %2d FAILED: read %h at addr %4d but should have been %h", testnum, dcif.imemload, addr, 32'hDEADBEEF);

	
	// TEST 2: same address, cache hit
	testnum++;
	#(PERIOD*2);
	if (dcif.imemload == 32'hDEADBEEF)
	  $display("TEST %2d passed", testnum);
	else 
	  $display("TEST %2d FAILED: read %h at addr %4d but should have been %h", testnum, dcif.imemload, addr, dcif.dmemstore);

	
	$display("\n***** END OF TESTS *****\n\n");
	$finish;
     end

endprogram
   

