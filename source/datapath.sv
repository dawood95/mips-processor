/*
  Everett Berry
  epberry@purdue.edu

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

`include "datapath_cache_if.vh"
`include "register_file_if.vh"
`include "alu_if.vh"
`include "cpu_types_pkg.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
  );

  // import types
  import cpu_types_pkg::*;

  // local variables
  word_t instr;
  i_t iinstr;
  j_t jinstr;
  r_t rinstr;
  word_t imm_ext, pc, pc_next;
  logic busA_sel; // 0 for rs, 1 for immediate
  logic reg_wr_sel; // 0 for alu, 1 for memory
  logic reg_dst; // 0 for rd, 1 for rt
  logic imm_ext_sel; // 0 for zero, 1 for sign
  logic r_req, w_req, pcEn, halt;
  logic [1:0] busB_sel; // 00 for rt, 01 for shamt, 10 for imm_ext, 11 for 32'd16


  // initialized from singlecycle.sv
  parameter PC_INIT = 0;

  // interfaces
  alu_if alif();
  register_file_if rfif();

  // connected modules
  register_file reg_file( CLK, nRST, rfif);

  request_unit req_unit(.CLK(CLK),
    .nRST(nRST),
    .halt(dpif.halt),
    .r_req(r_req),
    .w_req(w_req),
    .iHit(dpif.ihit),
    .dHit(dpif.dhit),
    .iRen(dpif.imemREN),
    .dRen(dpif.dmemREN),
    .dWen(dpif.dmemWEN)
    );

  control_unit control_unit(.instr(instr),
    .zf(alif.zero),
    .of(alif.overflow),
    .aluOp(alif.opcode),
    .busB_sel(busB_sel),
    .busA_sel(busA_sel),
    .imm_ext_sel(imm_ext_sel),
    .reg_dst(reg_dst),
    .reg_wr_sel(reg_wr_sel),
    .memREN(r_req),
    .memWEN(w_req),
    .regWEN(rfif.WEN),
    .halt(halt)
     );

  alu alu(alif);

  // instr cast
  always_comb
    begin
      iinstr = i_t'(instr);
      rinstr = r_t'(instr);
    end

  always_comb
    begin
      instr = dpif.imemload;
      imm_ext = (imm_ext_sel) ? {{16{iinstr.imm[15]}},iinstr.imm} : {16'b0,iinstr.imm} ;
      alif.portA = (busA_sel) ? imm_ext : rfif.rdat1;

      case(busB_sel)
        2'b00: alif.portB = rfif.rdat2;
        2'b01: alif.portB = rinstr.shamt;
        2'b10: alif.portB = imm_ext;
        2'b11: alif.portB = 32'd16;
      endcase

      case(reg_dst)
        2'b00, 2'b11: rfif.wsel = rinstr.rd;
        2'b01: rfif.wsel = rinstr.rt;
        2'b10: rfif.wsel = 5'd31;
      endcase

      rfif.rsel1 = rinstr.rs;
      rfif.rsel2 = rinstr.rt;

      case(reg_wr_sel)
        1'b0: rfif.wdat = alif.outPort;
        1'b1: rfif.wdat = dpif.dmemload;
      endcase

      // memory operations
      dpif.dmemaddr = alif.outPort;
      dpif.dmemstore = rfif.rdat2;
      dpif.imemaddr = pc;

      // pc
      pc_next = pc + 4;
      pcEn = ~dpif.dmemREN & ~dpif.dmemWEN;
    end

  // program counter
  always_ff @(posedge CLK, negedge nRST)
    begin
      if(!nRST)
        pc <= PC_INIT;
      else if(pcEn & !dpif.halt)
        pc <= pc_next;
    end

  // halt latch
  always_ff @(posedge CLK, negedge nRST)
    begin
      if(!nRST)
        dpif.halt <= 1'b0;
      else
        dpif.halt <= halt;
    end

endmodule // datapath
