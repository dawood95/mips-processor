/*
  Eric Villasenor
  evillase@gmail.com

  register file interface
*/
`ifndef REGISTER_FILE_IF_VH
`define REGISTER_FILE_IF_VH

// all types
`include "cpu_types_pkg.vh"

interface register_file_if;
  // import types
  import cpu_types_pkg::*;

  logic     WEN;
  regbits_t wsel, rsel1, rsel2;
  word_t    wdat, rdat1, rdat2;

  // register file ports
  modport rf (
    input   WEN, wsel, rsel1, rsel2, wdat,
    output  rdat1, rdat2
  );
  // register file tb
  modport tb (
    input   rdat1, rdat2,
    output  WEN, wsel, rsel1, rsel2, wdat
  );
endinterface

`endif //REGISTER_FILE_IF_VH


/*
module datapath (
input logic CLK, nRST,
datapath_cache_if.dp dpif
);
// import types
import cpu_types_pkg::*;
// pc init
parameter PC_INIT = 0;
register_file_if rfif ();
control_unit_if cuif ();
request_unit_if ruif ();
alu_if aluif ();
pc_if pcif ();
register_file register(CLK, nRST, rfif);
control_unit control(cuif);
request_unit request(CLK, nRST, dpif, ruif);
alu alu(aluif);
pc pc(CLK, nRST, pcif);
// intermediate vars
r_t rtype;
i_t itype;
j_t jtype;
assign rtype = r_t'(dpif.imemload);
assign itype = i_t'(dpif.imemload);
assign jtype = j_t'(dpif.imemload);
word_t extended;
word_t swizzle_output;
word_t pcplus4, jumpaddr, branchaddr, jraddr;
word_t pca, pcb, pcnext;
logic pcacontrol;
// register inputs
regbits_t rt_or_31;
assign rfif.WEN = cuif.regwrite;
assign rt_or_31 = cuif.jal ? '1 : rtype.rt;
assign rfif.wsel = cuif.regdest ? rtype.rd : rt_or_31;
assign rfif.rsel1 = rtype.rs;
assign rfif.rsel2 = rtype.rt;
assign rfif.wdat = cuif.memtoreg ? dpif.dmemload : aluif.out;
// control unit inputs
assign cuif.instruction = dpif

  parameter PC_INIT = 0;.imemload;
// request unit inputs
assign ruif.halt = cuif.halt;
assign ruif.memread = cuif.memread;
assign ruif.memwrite = cuif.memwrite;
assign ruif.imemaddr = pcif.address;
assign ruif.dmemstore = rfif.rdat2;
assign ruif.dmemaddr = aluif.out;
// alu inputs
assign aluif.opcode = cuif.aluop;
assign aluif.a = rfif.rdat1;
assign aluif.b = cuif.shift ? ({27'b0, rtype.shamt}) : (cuif.alusrc ? swizzle_output : rfif.rdat2);
// pc inputs
assign pcif.next_address = pcnext;
assign pcif.pc_pause = ruif.pcpause;
// intermediate var calcs
assign extended = cuif.extendtype ? $signed(itype.imm) : $unsigned(itype.imm);
assign swizzle_output = cuif.lui ? {extended[15:0], extended[31:16]} : extended;
assign pcplus4 = pcif.address + 4;
assign jumpaddr = {pcif.address[31:28], jtype.addr, 2'b00};
assign branchaddr = ($signed(swizzle_output << 2)) + pcplus4;
assign jraddr = rfif.rdat1;
assign pcacontrol = (cuif.branch & (cuif.bne ^ aluif.zero));
assign pca = pcacontrol ? branchaddr : pcplus4;
assign pcb = cuif.jump ? jumpaddr : pca;
assign pcnext = cuif.jr ? jraddr : pcb;
endmodule

*/

