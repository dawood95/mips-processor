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
  test PROG (CLK, nRST, aluif);
  // DUT
`ifndef MAPPED
  alu DUT(CLK, nRST, aluif);
`else
  alu DUT(
    .\aluif.opcode (aluif.opcode),
    .\aluif.portA (aluif.portA),
    .\aluif.portB (aluif.portB),
    .\aluif.outPort (aluif.outPort),
    .\aluif.negative (aluif.negative),
    .\aluif.overflow (aluif.overflow),
    .\aluif.zero (aluif.zero),
    .\nRST (nRST),
    .\CLK (CLK)
  );
`endif

endmodule


program test
import cpu_types_pkg::*;
(
  input logic CLK,
  output logic nRST,
  aluif aluif_tb
);

initial begin
  parameter PERIOD = 10;
  int testnum, chknRST, i;

  // initial reset
  nRST = 0;
  #(PERIOD);
  nRST = 1;
  #(PERIOD);

  // write values into every register
/*
  rfif_tb.WEN = 1;
  for (int i=1; i <= 32; i++) begin
    rfif_tb.wsel = i-1;
    rfif_tb.wdat = i;
    #(PERIOD);
  end
*/

  $display("\n\n***** START OF TESTS *****\n");

  // TEST 1: subtraction - basic
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = 32'd40;
  aluif_tb.portB = 32'd50;
  #(PERIOD);
  if (aluif_tb.outPort == 32'd90) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: output = %d", testnum, aluif_tb.outPort);

  // TEST 2: addition - zero flag
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = -40;
  aluif_tb.portB = 32'd40;
  #(PERIOD);
  if (aluif_tb.zero) $display("TEST %2d passed", testnum);
  else $error("TEST %2d FAILED: zero flag not set", testnum);

  // TEST 3: addition - overflow flag
  testnum++;
  aluif_tb.opcode = ALU_ADD;
  aluif_tb.portA = 1800000000;
  aluif_tb.portB = 1800000000;
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
  testnum++;
  aluif_tb.opcode = ALU_SUB;
  aluif_tb.portA = -180000000;
  aluif_tb.portB = 1800000000;
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

/*
  // TEST 1: check that register[0] is 0 even though we wrote a 1
  testnum = 1;
  rfif_tb.rsel1 = 0;
  #(PERIOD);
  if (rfif_tb.rdat1 != 0) $error("TEST 1 passed: register[0] is %d", rfif_tb.rdat1);
  else $display("TEST  1 PASSED");

  // TEST 2-33: check the values in every register
  for (i=1; i<32; i++) begin
    testnum++;
    rfif_tb.rsel1 = i;
    #(PERIOD);
    if (rfif_tb.rdat1 == i+1) $display("TEST %2d passed", testnum);
    else $error("TEST %d FAILED: rfif_tb.rdat1 = %d", i, rfif_tb.rdat1);
  end

  // TEST 34: asynchronous reset
  testnum++;
  nRST = 0;
  #(PERIOD);
  for (i=0; i<32; i++) begin
    rfif_tb.rsel2 = i;
    #(PERIOD)
    if (rfif_tb.rdat2 != 0)
    begin
      break;
      chknRST = 0;
    end
    else chknRST = 1;
  end

  if (!chknRST) $error("TEST 34 FAILED at reg %d", i);
  else $display("TEST 34 passed");
*/

  #(PERIOD);

  $display("\n***** END OF TESTS *****\n\n");
end

endprogram
