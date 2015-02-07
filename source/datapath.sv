/*
  Everett Berry
  epberry@purdue.edu

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

// data path interface
`include "datapath_cache_if.vh"

`include "cpu_types_pkg.vh"
`include "register_file_if.vh"
`include "alu_if.vh"
`include "control_unit_if.vh"
`include "request_unit_if.vh"
`include "pc_if.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);

  import cpu_types_pkg::*;

  parameter PC_INIT = 0;

  // initialize all the interfaces
  register_file_if rfif ();
  control_unit_if cuif ();
  request_unit_if ruif ();
  alu_if aluif ();
  // pc_if pcif ();

  // hook the modules together
  // pc program_ctr(CLK, nRST, pcif);
  register_file register(CLK, nRST, rfif);
  control_unit control(CLK, nRST, cuif);
  request_unit request(CLK, nRST, ruif);
  alu alu2(aluif);

  // local vars
  r_t rtype;
  i_t itype;
  j_t jtype;
  word_t extender, pcplus, jumpaddr, branchaddr, jraddr, luihelp;
  word_t pc, pcnext; // might also need pca and pcb
  logic halt, haltnext; // latch halt
  regbits_t rt_or_31;
  // logic pcacontrol;

  // pc
  always_ff @(posedge CLK, negedge nRST)
  begin
    if (!nRST)
      pc <= PC_INIT;
    else if (!halt) // PC = ihit & !dhit & !halt
      pc <= pcnext;
  end

  // latched halt
  always_ff @(posedge CLK, negedge nRST)
  begin
    if (!nRST)
      halt <= 1'b0;
    else
      halt <= haltnext;
  end

  // glue logic
  always_comb
  begin
    // cast types
    rtype = r_t'(dpif.imemload);
    itype = i_t'(dpif.imemload);
    jtype = j_t'(dpif.imemload);

    // local computation
    extender = cuif.ext ? $signed(itype.imm) : $unsigned(itype.imm);
    luihelp = cuif.lui ? {extender[15:0], extender[31:16]} : extender;
    // pcplus = pcif.addr + 4;
    jumpaddr = {pcif.addr[31:28], jtype.addr, 2'b00};
    branchaddr = ($signed(luihelp << 2)) + pcplus;
    jraddr = rfif.rdat1;

    pcnext = pcnext + 4;
    haltnext = cuif.halt;
    // pcacontrol = (cuif.branch & (cuif.bne ^ aluif.zero));
    // pca = pcacontrol ? branchaddr : pca;
    // pcb = cuif.jump ? jumpaddr : pca;
    // pcnext = cuif.jumpreg ? jraddr : pcb;
  end

  // module connections
  always_comb
  begin
    // register
    rfif.WEN = cuif.regwr;
    rt_or_31 = cuif.jumpal ? 1'b1 : rtype.rt;
    rfif.wsel = cuif.regdst ? rtype.rd : rt_or_31;
    rfif.rsel1 = rtype.rs;
    rfif.rsel2 = rtype.rt;
    rfif.wdat = cuif.memtoreg ? dpif.dmemload : aluif.outPort;

    // request unit
    // ruif.halt = cuif.halt;
    ruif.memread = cuif.memread;
    ruif.memwr = cuif.memwr;
    ruif.ihit = dpif.ihit;
    ruif.dhit = dpif.dhit;
    // ruif.dmemstore = rfif.rdat2;
    // ruif.dmemaddr = aluif.out;
    dpif.imemREN = ruif.iREN;
    dpif.dmemREN = ruif.dREN;
    dpif.dmemWEN = ruif.dWEN;

    // pc
    // pcif.next_addr = pcnext;
    // pcif.pc_pause = ~dpif.ihit | cuif.halt;
    dpif.imemaddr = pc;
    dpif.dmemaddr = aluif.outPort;

    // alu
    aluif.opcode = cuif.aluop;
    aluif.portA = rfif.rdat1;
    aluif.portB = cuif.shift ? ({27'b0, rtype.shamt}) : (cuif.alusrc ? luihelp : rfif.rdat2);

    // control unit
    cuif.instr = dpif.imemload;

    // cache
    dpif.halt = halt;

  end


endmodule
