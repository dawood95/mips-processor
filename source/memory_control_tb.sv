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

   memory_control DUT(ccif);
   
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
	nRST = 1'b1;
	nRST = 1'b0;
	ccif.iREN = 1'b1;
	ccif.dREN = 1'b0;
	ccif.dWEN = 1'b0;
	ccif.iaddr = 32'h00000000;
	ccif.daddr = 0;
	repeat (4) @(posedge CLK);
	$display("Reading instruction from address");
	$display("Instruction from address %h = %h",ccif.iaddr,ccif.iload);
	ccif.iaddr = 32'h00000004;
	ccif.daddr = 32'h00000008;
	repeat (4) @(posedge CLK);
	$display("Reading instruction from another address");
	$display("Instruction from address %h = %h",ccif.iaddr,ccif.iload);
	ccif.dREN = 1'b1;
	repeat (4) @(posedge CLK);
	$display("Reading data from address");
	$display("Instruction from address %h = %h",ccif.iaddr,ccif.iload);
	$display("Data from address %h = %h",ccif.daddr,ccif.dload);
	ccif.dREN = 1'b0;
	ccif.iREN = 1'b0;
	ccif.dWEN = 1'b1;
	ccif.daddr = 32'h00000004;
	ccif.dstore = 32'h00000001;
	repeat (4) @(posedge CLK);
	$display("Writing data to address");
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
   
