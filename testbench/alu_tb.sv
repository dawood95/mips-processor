/* Sheik Dawood
 - mg258
 - dawood0@purdue.edu
  Used Eric Villasenor's skeleton code
 ALU Test Bench
 */

`include "alu_if.vh"
`include "cpu_types_pkg.vh"
`timescale 1 ns / 1 ns

module alu_tb;

   alu_if alif();

   test PROG (alif);

`ifndef MAPPED
   alu DUT(alif);
`else
   alu DUT(
	   .\sv.porta (alif.porta),
	   .\sv.portb (alif.portb),
	   .\sv.op (alif.op),
	   .\sv.out (alif.out),
	   .\sv.nf (alif.nf),
	   .\sv.zf (alif.zf),
	   .\sv.of (alif.of)
	   );
`endif

endmodule // alu_tb

program test
  import cpu_types_pkg::*;
   (
    alu_if.tb tb
    );
   initial
     begin
	//Logical Shift Left
	$display("====================");
	$display("Logical Shift Left");
	tb.porta = 32'd5;
	tb.portb = 32'd1;
	tb.op = ALU_SLL;
	#5;
	$display("PortA  = %b\nPortB  = %32d\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	tb.porta = 32'd225;
	tb.portb = 32'd32;
	tb.op = ALU_SLL;
	#5;
	$display("PortA  = %b\nPortB  = %32d\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	//Logical Shift Right
	$display("====================");
	$display("Logical Shift Right");
	tb.porta = 32'd5;
	tb.portb = 32'd1;
	tb.op = ALU_SRL;
	#5;
	$display("PortA  = %b\nPortB  = %32d\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	tb.porta = 32'd345;
	tb.portb = 32'd32;
	tb.op = ALU_SRL;
	#5;
	$display("PortA  = %b\nPortB  = %32d\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	//Addition
	$display("====================");
	$display("Addition-basic");
	tb.porta = 32'd5;
	tb.portb = 32'd1;
	tb.op = ALU_ADD;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	$display("====================");
	$display("Addition- 1+ 1-");
	tb.porta = 32'd5;
	tb.portb = -32'd1;
	tb.op = ALU_ADD;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	$display("====================");
	$display("Addition- 1- 1-");
	tb.porta = -32'd5;
	tb.portb = -32'd1;
	tb.op = ALU_ADD;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	$display("====================");
	$display("Addition- Overflow");
	tb.porta = 2**31-1;
	tb.portb = 2**31-1;
	tb.op = ALU_ADD;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	//Sub
	$display("====================");
	$display("Sub-basic");
	tb.porta = 32'd5;
	tb.portb = 32'd1;
	tb.op = ALU_SUB;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	$display("====================");
	$display("Sub- 1+ 1-");
	tb.porta = 32'd5;
	tb.portb = -32'd1;
	tb.op = ALU_SUB;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	$display("====================");
	$display("Sub- 1- 1-");
	tb.porta = -32'd5;
	tb.portb = -32'd1;
	tb.op = ALU_SUB;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	$display("====================");
	$display("Sub- Overflow");
	tb.porta = -(2**31-1);
	tb.portb = 5;
	tb.op = ALU_SUB;
	#5;
	$display("PortA  = %10d\nPortB  = %10d\nOutput = %10d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),$signed(tb.out),tb.nf,tb.of,tb.zf);
	//AND
	$display("====================");
	$display("AND");
	tb.porta = 2**31+1;
	tb.portb = 2*15+255;
	tb.op = ALU_AND;
	#5;
	$display("PortA  = %b\nPortB  = %b\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	//OR
	$display("====================");
	$display("OR");
	tb.porta = 2**31;
	tb.portb = 2*15+255;
	tb.op = ALU_OR;
	#5;
	$display("PortA  = %b\nPortB  = %b\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	//XOR
	$display("====================");
	$display("XOR");
	tb.porta = 2**31+9;
	tb.portb = 2*15+255;
	tb.op = ALU_XOR;
	#5;
	$display("PortA  = %b\nPortB  = %b\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	//NOR
	$display("====================");
	$display("NOR");
	tb.porta = 2**31;
	tb.portb = 2*15+255;
	tb.op = ALU_NOR;
	#5;
	$display("PortA  = %b\nPortB  = %b\nOutput = %b\nNF = %d VF = %d ZF = %d",tb.porta,tb.portb,tb.out,tb.nf,tb.of,tb.zf);
	//SLT
	$display("====================");
	$display("Set Less that Signed");
	tb.porta = -5;
	tb.portb = 2;
	tb.op = ALU_SLT;
	#5;
	$display("PortA  = %d\nPortB  = %d\nOutput = %d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),tb.out,tb.nf,tb.of,tb.zf);
	//SLTU
	$display("====================");
	$display("Set Less that UnSigned");
	tb.porta = -5;
	tb.portb = 2;
	tb.op = ALU_SLTU;
	#5;
	$display("PortA  = %d\nPortB  = %d\nOutput = %d\nNF = %d VF = %d ZF = %d",$signed(tb.porta),$signed(tb.portb),tb.out,tb.nf,tb.of,tb.zf);
     end
endprogram // test

