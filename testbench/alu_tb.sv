/*
  Eric Villasenor
  evillase@gmail.com

  register file test bench
*/

// mapped needs this
`include "alu_if.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module alu_tb;

  parameter PERIOD = 10;

  logic CLK = 0, nRST;

  // test vars
  int v1 = 1;
  int v2 = 4721;
  int v3 = 25119;

  // clock
  always #(PERIOD/2) CLK++;

  // interface
  alu_if aluif ();
  // test program
  test PROG (aluif);
  // DUT
`ifndef MAPPED
  alu DUT(aluif);
`else
  alu DUT(
    .\aluif.opcode (aluif.opcode),
    .\aluif.portA (aluif.portA),
    .\aluif.portB (aluif.portB),
    .\aluif.outPort (aluif.outPort),
    .\aluif.negative (aluif.negative),
    .\aluif.overflow (aluif.overflow),
    .\aluif.zero (aluif.zero)
  );
`endif

endmodule


program test
import cpu_types_pkg::*;
(
  alu_if.tb aluif_tb
);

initial begin
  parameter PERIOD = 10;
  int testnum, chknRST, i;

  $display("\n\n***** START OF TESTS *****\n");

  // TEST 1: subtraction - basic
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = 32'd40;
  aluif_tb.portB = 32'd50;
  #(PERIOD);
  if (aluif_tb.outPort == 32'd90) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: output = %d", testnum, aluif_tb.outPort);

  // TEST 2 addition - zero flag
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = -40;
  aluif_tb.portB = 32'd40;
  #(PERIOD);
  if (aluif_tb.zero) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: zero flag not set", testnum);

  // TEST 3: addition - overflow flag bits
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = 32'b01111111111111111111111111111111;// 1800000001;
  aluif_tb.portB = 32'b00000000000000000000000000000001;// 1800000001;
  #(PERIOD);
  if (aluif_tb.overflow) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: overflow flag not set", testnum);


  // TEST 4: addition - negative flag
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = -200;
  aluif_tb.portB = -300;
  #(PERIOD);
  if (aluif_tb.negative) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: negative flag not set", testnum);

  // TEST 5: subtraction - basic
  testnum++;
  aluif_tb.opcode = ALU_SUB;
  aluif_tb.portA = 10000;
  aluif_tb.portB = 6000;
  #(PERIOD);
  if (aluif_tb.outPort == 4000) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: subtraction result = %d", testnum,
aluif_tb.outPort);

  // TEST 6: subtraction - zero flag
  testnum++;
  aluif_tb.opcode = ALU_SUB;
  aluif_tb.portA = 40;
  aluif_tb.portB = 40;
  #(PERIOD);
  if (aluif_tb.zero) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: zero flag not set", testnum);

  // TEST 7: subtraction - overflow flag
  /********** OVERFLOW NEEDS MORE TESTING ******************/
  testnum++;
  aluif_tb.opcode = ALU_SUB;
  aluif_tb.portA = -1800000000;
  aluif_tb.portB = 1800000001;
  #(PERIOD);
  if (aluif_tb.overflow) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: overflow flag not set", testnum);

  // TEST 8: subtraction - negative flag
  testnum++;
  aluif_tb.opcode = ALU_SUB;
  aluif_tb.portA = 600;
  aluif_tb.portB = 1000;
  #(PERIOD);
  if (aluif_tb.negative) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: negative flag not set", testnum);

  // TEST 9: addition - overflow flag large numbers
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = 1800000001;
  aluif_tb.portB = 1800000001;
  #(PERIOD);
  if (aluif_tb.overflow) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: overflow flag not set", testnum);

  #(PERIOD);

  $display("\n***** END OF TESTS *****\n\n");
end

endprogram
