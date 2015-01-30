/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Test bench for memory controller
 
 */

`include "cache_control_if.vh"

`include "cpu_types_pkg.vh"

`timescale 1ns/1ns

module memory_control_tb:
  
  parameter PERIOD = 20;
   
   logic CLK = 1, nRST;

   //Clock gen
   always #(PERIOD/2) CLK++;

   cache_control_if ccif();

   
endmodule // memory_control_tb

program test(

	     );
   import cpu_types_pkg::*;

   
   task automatic dump_memory();
      string filename = "memcpu.hex";
      int    memfd;
      
      syif.tbCTRL = 1;
      syif.addr = 0;
      syif.WEN = 0;
      syif.REN = 0;
      
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
	   
	   syif.addr = i << 2;
	   syif.REN = 1;
	   repeat (4) @(posedge CLK);
	   if (syif.load === 0)
             continue;
	   values = {8'h04,16'(i),8'h00,syif.load};
	   foreach (values[j])
             chksum += values[j];
	   chksum = 16'h100 - chksum;
	   ihex = $sformatf(":04%h00%h%h",16'(i),syif.load,8'(chksum));
	   $fdisplay(memfd,"%s",ihex.toupper());
	end //for
      if (memfd)
	begin
	   syif.tbCTRL = 0;
	   syif.REN = 0;
	   $fdisplay(memfd,":00000001FF");
	   $fclose(memfd);
	   $display("Finished memory dump.");
	end
   endtask // dump_memory
   
endprogram // test
   
