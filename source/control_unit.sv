/*
  Everett Berry
  epberry@purdue.edu

  control unit for the datapath
*/

`include "cpu_types_pkg.vh"
`include "control_unit_if.vh"

module control_unit (
  input logic CLK, nRST,
  control_unit_if.control cuif
);

  import cpu_types_pkg::*;

  opcode_t opcode;
  funct_t func;

  // cast instruction to take advantage of cpu types
  opcode = opcode_t'(cuif.instr[31:26]);
  func = funct_t'(cuif.instr[5:0]);

  always_comb
  begin
    // Control signals which default to 0
    cuif.alusrc = 1'b0; cuif.lui = 1'b0; cuif.shift = 1'b0;
    cuif.memwr = 1'b0; cuif.memread = 1'b0; cuif.memtoreg = 1'b0;
    cuif.regdst = 1'b0; cuif.halt = 1'b0; cuif.jal = 1'b0;
    cuif.lui = 1'b0; cuif.alusrc = 1'b0; cuif.bne = 1'b0;
    cuif.branch = 1'b0; cuif.jump = 1'b0; cuif.jumpr = 1'b0;

    // Control signals which default to 1
    cuif.regwr = 1'b1; cuif.ext = 1'b1;

    // Other default
    cuif.aluop = aluop_t'('1);

    casez (opcode)
      /*********** R-type ******************/
      RTYPE:
      begin
        cuif.regdst = 1'b1;
        casez(func)
          ADDU, ADD: cuif.aluop = ALU_ADD;
          AND: cuif.aluop = ALU_AND;
          JR: begin
            cuif.jumpreg = 1'b1;
            cuif.regwr = 1'b1;
          end
          NOR: cuif.aluop = ALU_NOR;
          OR: cuif.aluop = ALU_OR;
          SLT: cuif.aluop = ALU_SLT;
          SLTU: cuif.aluop = ALU_SLTU;
          SLL: begin
            cuif.shift = 1'b1;
            cuif.aluop = ALU_SLL;
          end
          SRL: begin
            cuif.shift = 1'b1;
            cuif.aluop = ALU_SRL;
          end
          SUB, SUBU: cuif.aluop = ALU_SUB;
          XOR: cuif.aluop = ALU_XOR;
        endcase
      end

      /********* I-type *************/
      ADDIU: begin
        cuif.alusrc = 1'b1;
        cuif.aluop = ALU_ADD;
      end
      ADDI: begin
        // ???
        cuif.alusrc = 1'b1;
        cuif.aluop = ALU_ADD;
        cuif.ext = 1'b0;
      ANDI: begin
        cuif.alusrc = 1'b1;
        cuif.ext = 1'b0;
        cuif.aluop = ALU_AND;
      end
      BEQ, BNE: begin
        cuif.regwr = 1'b0;
        cuif.branch = 1'b1;
        cuif.aluop = ALU_SUB;
      end
      LUI: begin
        cuif.lui = 1'b1;
        cuif.alusrc = 1'b1;
        cuif.ext = 1'b0;
        cuif.aluop = ALU_OR;
      end
      LW: begin
        cuif.memread = 1'b1;
        cuif.alusrc = 1'b1;
        cuif.memtoreg = 1'b1;
        cuif.aluop = ALU_ADD;
      end
      ORI: begin
        cuif.alusrc = 1'b1;
        cuif.ext = 1'b0;
        cuif.aluop = ALU_OR;
      end
      SLTI: begin
        cuif.alusrc = 1'b1;
        cuif.aluop = ALU_SLT
      end
      SLTIU: begin
        cuif.alusrc = 1'b1;
        cuif.aluop = ALU_SLTU;
      end
      SW: begin
        cuif.memwrite = 1'b1;
        cuif.regwrite = 1'b0;
        cuif.alusrc = 1'b1;
        cuif.aluop = ALU_ADD;
      end
      XORI: begin
        cuif.alusrc = 1'b1;
        cuif.ext = 1'b0;
      end

      /******** J-type ********/
      J: begin
        cuif.regwr = 1'b0;
        cuif.jump = 1'b1;
      end
      JAL: begin
        cuif.jumpal = 1'b1;
        cuif.jump = 1'b1;
      end

      /******** Other **********/
      HALT: begin
        cuif.halt = 1'b1;
        cuif.regwr = 1'b0;
      end

    endcase
  end

endmodule
