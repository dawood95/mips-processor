/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Test bench for memory controller
 
 */

`include "cache_control_if.vh"
`include "cpu_ram_if.vh"
`include "cpu_types_pkg.vh"
`timescale 1ns/1ns

module memory_control_tb;
   
   parameter PERIOD = 20;
   
   logic CLK = 1, nRST;

   //Clock gen
   always #(PERIOD/2) CLK++;

   cache_control_if ccif();
   cpu_ram_if ramif();
   
   assign ramif.ramWEN = ccif.ramWEN;
   assign ramif.ramREN = ccif.ramREN;
   assign ramif.ramstore = ccif.ramstore;
   assign ramif.ramaddr = ccif.ramaddr;
   assign ccif.ramload = ramif.ramload;
   assign ccif.ramstate = ramif.ramstate;
   
   test PROG (CLK,nRST,ccif);

   memory_control DUT(CLK, nRST, ccif);
   
   ram Ram (.CLK(CLK),
	    .nRST(nRST),
	    .ramif(ramif)
	    );
   
   
endmodule // memory_control_tb

program test(
	     input logic CLK,
	     output logic nRST,
	     cache_control_if.caches ccif
	     );
   import cpu_types_pkg::*;

   initial
     begin
	//	dump_memory();
	// $monitor("iWAIT[0] = %d, dWAIT[0] = %d, iWAIT[1] = %d, dWAIT[1] = %d",ccif.iwait[0],ccif.dwait[0],ccif.iwait[1],ccif.dwait[1]);
	// $monitor("Check coherence P0: ccwait[0] = %d, ccinv[0] =%d, ccsnoopaddr[0] = %h", ccif.ccwait[0], ccif.ccinv[0], ccif.ccsnoopaddr[0]);
	// $monitor("Check coherence P1: ccwait[1] = %d, ccinv[1] =%d, ccsnoopaddr[1] = %h", ccif.ccwait[1], ccif.ccinv[1], ccif.ccsnoopaddr[1]);
	
	nRST = 1'b0;
	@(posedge CLK);
	nRST = 1'b1;

	$display("Start tests");
	// Set P1
	ccif.iaddr[1] = 0;
	ccif.iREN[1] = 0;
	ccif.dWEN[1] = 0;
	ccif.dREN[1] = 0;
	ccif.dstore[1] = 0;
	ccif.daddr[1] = 0;
	ccif.ccwrite[1] = 0;
	ccif.cctrans[1] = 0;
	
	$display("Test 1: Write some data to P0");
	ccif.iaddr[0] = 0;
	ccif.iREN[0] = 0;
	ccif.dWEN[0] = 1;
	ccif.dREN[0] = 0;
	ccif.cctrans[0] = 0;
	ccif.ccwrite[0] = 1;
	ccif.dstore[0] = 32'hDEADBEEF;
	ccif.daddr[0] = 32'h000003e8;
	@(posedge CLK);
	// P0 should wait while a write completesa
	if (ccif.dwait[0] == 1)
	  $display("passed: ccif.dwait[0] = %2d", ccif.dwait[0]);
	else
	  $display("FAILED: ccif.dwait[0] = %2d", ccif.dwait[0]);
	repeat (4) @(posedge CLK); // allow write to complete
	$display("dwait[0] = %d", ccif.dwait[0]);
	ccif.dWEN[0] = 0;
	ccif.ccwrite[0] = 0;

	$display("Test 2: Read instruction from P0");
	@(posedge CLK);
	ccif.iREN[0] = 1'b1;
	ccif.dREN[0] = 1'b0;
	ccif.dWEN[0] = 1'b0;
	ccif.iaddr[0] = 32'h000003e8;
	ccif.daddr[0] = 0;
	repeat (4) @(posedge CLK);
	if (ccif.iaddr[0] == 32'hDEADBEEF)
	  $display("passed: Instruction from address %h = %h",ccif.iaddr[0],ccif.iload[0]);
	else
	  $display("FAILED: Instruction from address %h = %h",ccif.iaddr[0],ccif.iload[0]);

	/*
	ccif.iaddr = 32'h00000004;
	ccif.daddr = 32'h00000008;
	repeat (4) @(posedge CLK);
	$display("Reading instruction from another address");
	$display("Instruction from address %h = %h",ccif.iaddr,ccif.iload);
	ccif.dREN = 1'b1;
	repeat (4) @(posedge CLK);
	$display("Reading data from address while iREN = 1");
	$display("Instruction from address %h = %h",ccif.iaddr,ccif.iload);
	$display("Data from address %h = %h",ccif.daddr,ccif.dload);
	ccif.dREN = 1'b0;
	ccif.iREN = 1'b0;
	ccif.dWEN = 1'b1;
	ccif.daddr = 32'h00000004;
	ccif.dstore = 32'hdeadbeef;
	repeat (4) @(posedge CLK);
	$display("Writing data %h to address %h",ccif.dstore, ccif.daddr);
	dump_memory;
	ccif.dREN = 1'b1;
	ccif.iREN = 1'b0;
	ccif.dWEN = 1'b1;
	ccif.daddr = 32'h00000004;
	ccif.dstore = 32'hdeadb1ef;
	$display("Data from address %h = %h",ccif.daddr,ccif.dload);
	$display("Writing data %h to address %h",ccif.dstore, ccif.daddr);
	repeat (4) @(posedge CLK);
	 */

	$display("End tests");
	
	dump_memory;
     end



   
   task automatic dump_memory();
      string filename = "memcpu.hex";
      int    memfd;
      ccif.daddr = 0;
      ccif.dWEN = 0;
      ccif.dREN = 0;
      memfd = $fopen(filename,"w");
      if (memfd)
	$display("Starting memory dump.");
      else
	begin $display("Failed to open %s.",filename); $finish; end
      for (int unsigned i = 0; memfd && i < 16384; i++)
	begin
	   int chksum = 0;
	   bit [7:0][7:0] values;
	   string 	  ihex;
	   ccif.daddr = i << 2;
	   ccif.dREN = 1;
	   repeat (4) @(posedge CLK);
	   if (ccif.dload === 0)
             continue;
	   values = {8'h04,16'(i),8'h00,ccif.dload};
	   foreach (values[j])
             chksum += values[j];
	   chksum = 16'h100 - chksum;
	   ihex = $sformatf(":04%h00%h%h",16'(i),ccif.dload,8'(chksum));
	   $fdisplay(memfd,"%s",ihex.toupper());
	end //for
      if (memfd)
	begin
	   ccif.dREN = 0;
	   $fdisplay(memfd,":00000001FF");
	   $fclose(memfd);
	   $display("Finished memory dump.");
	end
   endtask // dump_memory
   
endprogram // test
   
