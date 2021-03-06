/*
 Sheik Dawood
 dawood0@purdue.edu
 
 Test bench for data cache
 
 */

`include "datapath_cache_if.vh"
`include "cache_control_if.vh"
`include "cpu_ram_if.vh"
`include "cpu_types_pkg.vh"

`timescale 1ns/1ns

module dcache_tb;

   parameter PERIOD = 20;
   parameter CPUS = 2;
   parameter CPUID = 0;
		    
   
   logic CLK = 1, nRST;

   always #(PERIOD/2) CLK++;

   int 	 count = 0;
   always@(posedge CLK)
     count++;
   
   cache_control_if ccif();
   cpu_ram_if ramif();
   datapath_cache_if dcif();

   always@(dcif.dhit)
     begin
	if(dcif.dhit)
	  begin
	     $display("************\n%d\nCLK = %d\ndhit = %d\n******",$time,count,dcif.dhit);
	     count = 0;
	  end
     end
  
   assign ramif.ramWEN = ccif.ramWEN;
   assign ramif.ramREN = ccif.ramREN;
   assign ramif.ramstore = ccif.ramstore;
   assign ramif.ramaddr = ccif.ramaddr;
   assign ccif.ramload = ramif.ramload;
   assign ccif.ramstate = ramif.ramstate;

   test PROG(.CLK(CLK), .nRST(nRST), .dcif(dcif) , .ccif(ccif));
   dcache DUT(.CLK(CLK),.nRST(nRST), .dcif(dcif), .ccif(ccif));
   memory_control mc(.CLK(CLK),.nRST(nRST), .ccif(ccif));
   ram Ram (.CLK(CLK),.nRST(nRST), .ramif(ramif));

endmodule // dcache_tb

program test(
	     input logic CLK,
	     output logic nRST,
	     datapath_cache_if.dp dcif,
	     cache_control_if.cc ccif
	     );
   import cpu_types_pkg::*;

   initial
     begin

   
	ccif.iaddr = 0;
	ccif.iREN = 0;
	dcif.dmemaddr = 32'h00000000;
	dcif.halt = 1'b0;
	dcif.dmemREN = 1'b0;
	dcif.dmemWEN = 1'b0;
	$display("Test Bench Started ...\n");
	$display("Reset ...\n");
	nRST = 1'b1;
	@(negedge CLK);
	nRST = 1'b0;
	@(negedge CLK);
	nRST = 1'b1;
	@(posedge CLK);
	$display("Test 1\n");
	dcif.dmemREN = 1'b1;
	dcif.dmemaddr = 32'h00000300;
	
	$display("READING %h",dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	
	@(posedge CLK);
	dcif.dmemaddr = 32'h00000304;
	$display("READING %h",dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	dcif.dmemREN = 1'b0;
	@(posedge CLK);
	
	@(posedge CLK);
	dcif.dmemREN = 1'b1;
	dcif.dmemaddr = 32'h00000200;
	$display("READING %h",dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	@(posedge CLK);
	dcif.dmemaddr = 32'h00000204;
	$display("READING %h",dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	@(posedge CLK);
	dcif.dmemREN = 1'b0;
	@(posedge CLK);
	dcif.dmemWEN = 1'b1;
	dcif.dmemaddr = 32'h00000300;
	dcif.dmemstore = 32'habcdef12;
	$display("WRITING %h to %h",dcif.dmemstore,dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);

	dcif.dmemaddr = 32'h0000304;
	dcif.dmemstore = 32'habcdef13;
	$display("WRITING %h to %h",dcif.dmemstore,dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	dcif.dmemaddr = 32'h00000200;
	dcif.dmemstore = 32'habcdef14;
	$display("WRITING %h to %h",dcif.dmemstore,dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	dcif.dmemWEN = 1'b0;
	@(posedge CLK);
	dcif.dmemREN = 1'b1;
	dcif.dmemaddr = 32'h00000100;
	$display("READING %h",dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	@(posedge CLK);
	dcif.dmemREN = 1'b1;
	dcif.dmemaddr = 32'h00000108;
	$display("READING %h",dcif.dmemaddr);
	@(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	dcif.dmemaddr = 32'h00000300;
	$display("READING %h",dcif.dmemaddr);
	@(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	@(posedge CLK);
		@(posedge CLK);
	dcif.dmemaddr = 32'h00000304;
	$display("READING %h",dcif.dmemaddr);
	if(!dcif.dhit)
	  @(posedge dcif.dhit);
	@(posedge CLK);
	$display("Data = %h",dcif.dmemload);
	@(posedge CLK);
	dcif.dmemREN = 1'b0;
	dcif.halt = 1'b1;
	@(posedge dcif.dhit);
	$display("Done");
//	ldb0->ldb1->wrb0->wrb1->ld0(shit)->ld1(shit)->ldb0
     end

      task automatic dump_memory();
      string filename = "memcpu.hex";
      int    memfd;
      ccif.daddr[0] = 0;
      ccif.dWEN[0] = 0;
      ccif.dREN[0] = 0;
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
	   ccif.daddr[0] = i << 2;
	   ccif.dREN[0] = 1;
	   repeat (4) @(posedge CLK);
	   if (ccif.dload[0] === 0)
             continue;
	   values = {8'h04,16'(i),8'h00,ccif.dload[0]};
	   foreach (values[j])
             chksum += values[j];
	   chksum = 16'h100 - chksum;
	   ihex = $sformatf(":04%h00%h%h",16'(i),ccif.dload[0],8'(chksum));
	   $fdisplay(memfd,"%s",ihex.toupper());
	end //for
      if (memfd)
	begin
	   ccif.dREN[0] = 0;
	   $fdisplay(memfd,":00000001FF");
	   $fclose(memfd);
	   $display("Finished memory dump.");
	end
      endtask
endprogram // test
   
