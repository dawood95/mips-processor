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

  // pc init
  parameter PC_INIT = 0;

  // Local variables
  word_t instr;
  i_t iinstr;
  j_t jinstr;
  r_t rinstr;

  word_t immExt, pc, pc_next;
  logic r_req, w_req, porta_sel, immExt_sel, pcEn, halt;
  logic [1:0] portb_sel, pc_sel, wMemReg_sel, regW_sel;
  alu_if alif();
  register_file_if rfif();


  always_comb
    begin
      // Instruction type cast
      iinstr = i_t'(instr);
      jinstr = j_t'(instr);
      rinstr = r_t'(instr);
    end

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
    .portb_sel(portb_sel),
    .porta_sel(porta_sel),
    .immExt_sel(immExt_sel),
    .pc_sel(pc_sel),
    .regW_sel(regW_sel),
    .wMemReg_sel(wMemReg_sel),
    .memREN(r_req),
    .memWEN(w_req),
    .regWEN(rfif.WEN),
    .halt(halt)
     );

  alu alu(alif);

  always_comb
    begin
      instr = dpif.imemload;
      immExt = (immExt_sel) ? {{16{iinstr.imm[15]}},iinstr.imm} : {16'b0,iinstr.imm} ;
      alif.portA = (porta_sel) ? immExt : rfif.rdat1;

      case(portb_sel)
        2'b00: alif.portB = rfif.rdat2;
        2'b01: alif.portB = rinstr.shamt;
        2'b10: alif.portB = immExt;
        2'b11: alif.portB = 32'd16;
      endcase // case (portb_sel)

      case(regW_sel)
        2'b00, 2'b11: rfif.wsel = rinstr.rd;
        2'b01: rfif.wsel = rinstr.rt;
        2'b10: rfif.wsel = 5'd31;
      endcase // case (regW_sel)

      rfif.rsel1 = rinstr.rs;
      rfif.rsel2 = rinstr.rt;

      case(wMemReg_sel)
        2'b00,2'b11 : rfif.wdat = alif.outPort;
        2'b01: rfif.wdat = dpif.dmemload;
        2'b10: rfif.wdat = pc+4;
      endcase

      // memory operations
      dpif.dmemaddr = alif.outPort;
      dpif.dmemstore = rfif.rdat2;
      dpif.imemaddr = pc;

      // pc
      pc_next = pc + 4;
      pcEn = ~dpif.dmemREN & ~dpif.dmemWEN;
    end

  //PC
  always_ff @(posedge CLK, negedge nRST)
    begin
      if(!nRST)
        pc <= PC_INIT;
      else if(pcEn & !dpif.halt)
        pc <= pc_next;
    end

  always_ff @(posedge CLK, negedge nRST)
    begin
      if(!nRST)
        dpif.halt <= 1'b0;
      else
        dpif.halt <= halt;
    end

endmodule // datapath
