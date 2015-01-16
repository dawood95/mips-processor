/* Sheik Dawood 
 - mg258 
 - dawood0@purdue.edu
  Used Eric Villasenor's skeleton code
 Register File Test Bench
 */

`include "register_file_if.vh"
`include "cpu_types_pkg.vh"
`timescale 1 ns / 1 ns

module register_file_tb;
   
   parameter PERIOD = 10;
   logic CLK = 0, nRST;

   // test vars
   int 	 v1 = 1;
   int 	 v2 = 4721;
   int 	 v3 = 25119;
   
   // clock
   always #(PERIOD/2) CLK++;
   
   // interface
   register_file_if rfif();
   // test program
   test PROG (
	      .CLK(CLK),
	      .nRST(nRST),
	      .WEN(rfif.WEN),
	      .rdat1(rfif.rdat1),
	      .rdat2(rfif.rdat2),
	      .wdat(rfif.wdat),
	      .rsel1(rfif.rsel1),
	      .rsel2(rfif.rsel2),
	      .wsel(rfif.wsel)
	      );
   // DUT
`ifndef MAPPED
   register_file DUT(CLK, nRST, rfif);
`else
   register_file DUT(
		     .\rf.rdat2 (rfif.rdat2),
		     .\rf.rdat1 (rfif.rdat1),
		     .\rf.wdat (rfif.wdat),
		     .\rf.rsel2 (rfif.rsel2),
		     .\rf.rsel1 (rfif.rsel1),
		     .\rf.wsel (rfif.wsel),
		     .\rf.WEN (rfif.WEN),
		     .\nRST (nRST),
		     .\CLK (CLK)
		     );
`endif
   
endmodule // register_file_tb

program test
  import cpu_types_pkg::*;
  (
   input logic 	CLK,
   input 	word_t rdat1, rdat2,
   output logic nRST, WEN,
   output 	word_t wdat,
   output 	regbits_t wsel, rsel1, rsel2
   );
   parameter PERIOD = 10;
   int 		i;
  
   initial
     begin
	$monitor("Register[%2d] = %10d Register[%2d] = %10d",rsel1,rdat1,rsel2,rdat2);
	nRST = 1'b1;
	WEN = 0;
	wdat = 0;
	wsel = 0;
	rsel1 = 0;
	rsel2 = 0;
	@(posedge CLK);
	nRST = 1'b0;
	$display("Initial Reset");
	@(posedge CLK);
	nRST = 1'b1;
	WEN = 1'b1;
	for (i = 0; i < 32; i++)
	  begin
	     wdat = 2**i;
	     wsel = i;
	     $display("Writing %10d to Register %10d", wdat, wsel);
	     @(posedge CLK);
	  end
	for (i = 0; i < 16; i++)
	  begin
	     rsel1 = i;
	     rsel2 = 31 - i;
	     @(posedge CLK);
	  end
	nRST = 1'b0;
	$display("Reset");
	for (i = 0; i < 16; i++)
	  begin
	     rsel1 = i;
	     rsel2 = 31 - i;
	     @(posedge CLK);
	  end
     end

endprogram // test
   
