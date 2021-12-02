`ifndef RV5STAGE_COMMON
`define RV5STAGE_COMMON

typedef struct packed {
  logic enable;
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

interface SystemBus #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 64,
  parameter MASK_WIDTH = DATA_WIDTH / 8;
);

  // ReadWrite Channel
  logic rw_ready, rw_valid;
  logic rw_we, w_ce;
  logic [ADDR_WIDTH-1:0] rw_addr;
  logic [DATA_WIDTH-1:0] r_data;
  logic [MASK_WDITH-1:0] w_mask;
  logic [DATA_WIDTH-1:0] w_data;

  // Invalidation Channel
  logic inv_ready, inv_valid;
  logic [ADDR_WIDTH-1:0] inv_addr;

  // System Bus Provider: i.e. System Cache
  modport provider (
    // ReadWrite Channel
    input rw_valid,
    input rw_addr,
    input rw_we,
    output rw_ready,
    output r_data,
    input w_mask,
    input w_data,
    input w_ce,

    // Invalidation Channel
    input inv_ready,
    output inv_valid,
    output inv_addr
  );

  // System Bus User: i.e. L1i/L1d
  modport user (
    // ReadWrite Channel
    output rw_valid,
    output rw_addr,
    output rw_we,
    input rw_ready,
    input r_data,
    output w_mask,
    output w_data,
    output w_ce,

    // Invalidation Channel
    output inv_ready,
    input inv_valid,
    input inv_addr
  );

endinterface

`endif
