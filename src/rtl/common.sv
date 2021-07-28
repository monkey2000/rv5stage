`ifndef RV5STAGE_COMMON
`define RV5STAGE_COMMON

typedef struct packed {
  logic [6:0] opcode;
  logic [4:0] rd;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [31:0] imm;

  logic [2:0] funct3;
  logic [6:0] funct7;

  logic reg_write;
  logic alu_src;
  logic pc_src;
  logic mem_read;
  logic mem_write;
  logic mem_to_reg;
} DecodeInfo;

`endif
