`include "cpu_types_pkg.vh"
`include "request_unit_if.vh"

`timescale 1 ns / 1 ns

import cpu_types_pkg::*;

module request_unit_tb;
  // interfaces
  request_unit_if ruif();

  // variables for tests
  logic CLK = 0;
  logic nRST;
  parameter PERIOD = 10;
  int testnum = 0;

  // test clock
  always #(PERIOD/2) CLK++;

  // DUT
  request_unit REQ_UNIT(CLK, nRST, ruif);

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
