`include "cache_control_if.vh"
`include "cpu_ram_if.vh"

`timescale 1 ns / 1 ns

import cpu_types_pkg::*;

module memory_control_tb;
  cache_control_if ccif();
  cpu_ram_if ramif();

  logic CLK = 0;
  logic nRST;
  parameter PERIOD = 10;
  parameter ADDR_MAX = 40;
  memory_control DUT(CLK, nRST, ccif);
  ram DRAM(CLK, nRST, ramif);

  always #(PERIOD/2) CLK++;

  assign ccif.ramstate = ramif.ramstate;
  assign ccif.ramload = ramif.ramload;
  assign ramif.ramWEN = ccif.ramWEN;
  assign ramif.ramstore = ccif.ramstore;
  assign ramif.ramREN = ccif.ramREN;
  assign ramif.ramaddr = ccif.ramaddr;

  initial begin
    int testnum;

    $display("\n\n***** START OF TESTS *****\n");

    // initial reset
    nRST = 1'b0;
    #(PERIOD*2);
    nRST = 1'b1;
    #(PERIOD*2);

    // TEST 1-40: write/read data to/from all addresses
    testnum++;
    ccif.dREN = 2'b00;
    ccif.dWEN = 2'b01;
    ccif.iREN = 2'b00;

    // write data to all addresses
    for (int i=0; i <= ADDR_MAX; i=i+4) begin
      ccif.daddr = i;
      ccif.dstore = i*16;
      #(PERIOD*5);
    end

    // read signals to verify the writes
    ccif.dREN = 2'b01;
    ccif.dWEN = 2'b00;
    ccif.dstore = 0;
    #(PERIOD*50);

    // read back the data we wrote
    for (int i=0; i <= ADDR_MAX; i=i+4) begin
      ccif.daddr = i;
      #(PERIOD*10);
      if (ccif.dload[0] == i*16)
      begin
        $display("TEST %2d passed", testnum);
      end else begin
        $display("TEST %2d FAILED: Write or read failed at address %h. Data was: %h but it should have been %h", testnum, i, ccif.dload[0], i*16);
      end
    end

    // output contents of RAM to file
    dump_memory();

    // TEST 41:

    $display("\n***** END OF TESTS *****\n\n");
    $finish;
  end


   /*
      This dump_memory function is provided
   */

   task automatic dump_memory();
    string filename = "memcpu.hex";
    int memfd;

    //ccif.tbCTRL = 1;
    ccif.daddr = 0;
    ccif.dWEN = 0;
    ccif.dREN = 0;

    memfd = $fopen(filename,"w");
    if (memfd)
      $display("Starting memory dump to %s", filename);
    else
      begin $display("Failed to open %s.",filename); $finish; end

    for (int unsigned i = 0; memfd && i < 16384; i++)
    begin
      int chksum = 0;
      bit [7:0][7:0] values;
      string ihex;

      ccif.daddr = i << 2;
      ccif.dREN = 1;
      repeat (2) @(posedge CLK);
      if (ccif.dload === 0)
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
      //ccif.tbCTRL = 0;
      ccif.dREN = 0;
      $fdisplay(memfd,":00000001FF");
      $fclose(memfd);
      $display("Finished memory dump.");
    end
  endtask
endmodule
