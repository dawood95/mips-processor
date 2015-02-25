`include "cpu_types_pkg.vh"
`include "request_unit_if.vh"

`timescale 1 ns / 1 ns

import cpu_types_pkg::*;

module request_unit_tb;

  // general test vars
  parameter PERIOD = 10;
  int testnum = 0;

  // DUT vars
  logic CLK = 0;
  logic nRST;
  word_t instr;
  logic pr_correct;
  word_t update_br_target;
  logic [1:0] w_index;
  logic [1:0] r_index;
  word_t br_target;
  logic take_br;
  logic [1:0] out_index;

  // test clock
  always #(PERIOD/2) CLK++;

  // DUT
  br_predict BRANCH_PREDICT(
    .CLK(CLK),
    .nRST(nRST),
    .instr(instr),
    .pr_correct(pr_correct),
    .update_br_target(update_br_target),
    .w_index,
    r_index,
    br_target,
    take_br,
    out_index);

  initial begin

    $display("\n\n***** START OF TESTS *****\n");

    // inital reset
    nRST = 1'b0;
    #(PERIOD*2);
    nRST = 1'b1;
    #(PERIOD*2);

    // TEST 1: control mem read write
    testnum++;
    ruif.memwr = 1'b1;
    ruif.ihit = 1'b1;
    ruif.dhit = 1'b0;
    #(PERIOD);
    @(negedge CLK);
    if (ruif.dWEN == 1'b1) $display("TEST %2d passed", testnum);
    else $error("TEST %2d FAILED: dWEN = %d", testnum, ruif.dWEN);

    // TEST 2: check dhit
    testnum++;
    ruif.dhit = 1'b1;
    #(PERIOD);
    if (ruif.dWEN == 1'b0) $display("TEST %2d passed", testnum);
    else $error("TEST %2d FAILED: dWEN = %d", testnum, ruif.dWEN);

    // TEST 3: control asserts mem read
    testnum++;
    ruif.memread = 1'b1;
    ruif.ihit = 1'b1;
    ruif.dhit = 1'b0;
    #(PERIOD);
    if (ruif.dREN == 1'b1) $display("TEST %2d passed", testnum);
    else $error("TEST %2d FAILED: dREN = %d", testnum, ruif.dREN);

    // TEST 4: check dhit
    testnum++;
    ruif.dhit = 1'b1;
    #(PERIOD);
    if (ruif.dREN == 1'b0) $display("TEST %2d passed", testnum);
    else $error("TEST %2d FAILED: dREN = %d", testnum, ruif.dREN);

    $display("\n***** END OF TESTS *****\n\n");
    $finish;

  end

endmodule
