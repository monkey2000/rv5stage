`ifndef RV5STAGE_COMMON
`define RV5STAGE_COMMON

typedef struct packed {
  logic [31:0] pc;
  logic [31:0] inst;
} FetchInfo;

typedef struct packed {
  logic enable;

  logic [31:0] pc;

  logic [6:0] opcode;
  logic [4:0] rd;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [31:0] imm;

  logic rd_valid;
  logic rs1_valid;
  logic rs2_valid;

  logic [2:0] funct3;
  logic [6:0] funct7;

  logic reg_write;
  logic alu_src;      // imm enable
  logic load_imm;     // LUI, AUIPC
  logic pc_rel;       // AUIPC
  logic branch;       // J, B
  logic uncond;       // J
  logic mem_read;     // Load
  logic mem_write;    // Store
  logic mem_to_reg;   // Load
} DecodeInfo;

typedef struct packed {
  logic enable;

  logic [4:0] rd;
  logic [31:0] data;
} ForwardInfo;

`define PC    0
`define IF_ID 1
`define ID_EX 2
`define EX_MA 3

typedef struct packed {
  logic stall_req;
  logic [3:0] flush_req;
} PipeRequest;

typedef struct packed {
  logic stall;
  logic flush;
} PipeControl;

`endif
