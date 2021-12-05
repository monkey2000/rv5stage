`ifndef RV5STAGE_EXECUTE
`define RV5STAGE_EXECUTE

`include "common.sv"

module execute(
  input logic clk,
  input logic rst,
  output PipeRequest req,
  input PipeControl pipe,
  input DecodeInfo info,
  input logic [31:0] rs1_data,
  input logic [31:0] rs2_data,
  input DecodeInfo mem_info,
  input logic [31:0] mem_out,
  output logic [31:0] alu_out,
  output logic [31:0] r2_out,
  output logic pc_w_enable,
  output logic [31:0] new_pc,
  output DecodeInfo info_ff
);

assign req.stall_req = 1'b0;

logic [31:0] exe_pc = info.pc;

logic [31:0] opr1, forward_rs2, opr2;

// Forward
logic forward_rs1_from_exe = info.enable && info_ff.enable && info_ff.rd_valid && info.rs1_valid && info.rs1 != 5'b00000 && info.rs1 == info_ff.rd;
logic forward_rs2_from_exe = info.enable && info_ff.enable && info_ff.rd_valid && info.rs2_valid && info.rs2 != 5'b00000 && info.rs2 == info_ff.rd;

logic forward_rs1_from_mem = info.enable && mem_info.enable && mem_info.rd_valid && info.rs1_valid && info.rs1 != 5'b00000 && info.rs1 == mem_info.rd;
logic forward_rs2_from_mem = info.enable && mem_info.enable && mem_info.rd_valid && info.rs2_valid && info.rs2 != 5'b00000 && info.rs2 == mem_info.rd;

assign opr1 = forward_rs1_from_exe ? alu_out : forward_rs1_from_mem ? mem_out : rs1_data;
assign forward_rs2 = forward_rs2_from_exe ? alu_out : forward_rs2_from_mem ? mem_out : rs2_data;
assign opr2 = info.alu_src ? info.imm : forward_rs2;

logic logic_out;
logic [31:0] u_out;
logic [31:0] out;

// Load immediate
always_comb begin
  u_out = info.load_imm ? (info.pc_rel ? info.pc + info.imm : info.imm) : 32'h00000000;
end

// Branch Logic
always_comb begin
  case (info.funct3)
  3'b000: begin // BEQ
    logic_out = (opr1 == opr2);
  end
  3'b001: begin // BNE
    logic_out = (opr1 != opr2);
  end
  3'b100: begin // BLT
    logic_out = $signed(opr1) < $signed(opr2);
  end
  3'b101: begin // BGE
    logic_out = $signed(opr1) >= $signed(opr2);
  end
  3'b110: begin // BLTU
    logic_out = opr1 < opr2;
  end
  3'b111: begin // BGEU
    logic_out = opr1 >= opr2;
  end
  default: begin
    logic_out = 1'b0;
  end
  endcase
end

// Branch and Jump
logic [31:0] next_pc;

always_comb begin
  next_pc = info.pc + 32'h00000004;
  new_pc = info.pc_rel ? info.pc + info.imm : opr1 + info.imm;
end

always_comb begin
  pc_w_enable = (info.branch && (logic_out || info.uncond));
  req.flush_req = (info.branch && (logic_out || info.uncond)) ? 4'b0110 : 4'b0000;
end

// Arithmetic
always_comb begin
  casez ({info.alu_src, info.funct3, info.funct7[5]})
  5'b1_000_?, 5'b0_000_0: begin // ADDI, ADD
    out = opr1 + opr2;
  end
  5'b0_000_1: begin // SUB
    out = opr1 - opr2;
  end
  5'b?_100_?: begin // XORI, XOR
    out = opr1 ^ opr2;
  end
  5'b?_110_?: begin // ORI, OR
    out = opr1 | opr2;
  end
  5'b?_111_?: begin // ANDI, AND
    out = opr1 & opr2;
  end
  5'b?_001_?: begin // SLLI, SLL
    out = opr1 << opr2[4:0];
  end
  5'b?_101_0: begin // SRLI, SRL
    out = opr2 >> opr2[4:0];
  end
  5'b?_101_1: begin // SRAI, SRA
    out = $signed(opr2) >> opr2[4:0];
  end
  5'b?_010_?: begin // SLTI, SLT
    out = ($signed(opr1) < $signed(opr2)) ? 32'h00000001 : 32'h00000000;
  end
  5'b?_011_?: begin // SLTIU, SLTU
    out = (opr1 < opr2) ? 32'h00000001 : 32'h00000000;
  end
  default: begin
    out = 32'h00000000;
  end
  endcase
end

// Memory AddrGen
logic [31:0] addr_gen;
always_comb begin
  addr_gen = opr1 + info.imm;
end

// Dff
always_ff @ (posedge clk) begin
  if (rst) begin
    alu_out <= 32'h00000000;
  end else if (pipe.flush) begin
    alu_out <= 32'h00000000;
  end else if (pipe.stall) begin
    alu_out <= alu_out;
  end else begin
    alu_out <= info.enable ? (info.load_imm ? u_out : (info.uncond ? next_pc : ((info.mem_read || info.mem_write) ? addr_gen : out))) : 32'h00000000;
  end
end

// Dff
always_ff @(posedge clk) begin
  if (rst) begin
    r2_out <= 32'h00000000;
  end else if (pipe.flush) begin
    r2_out <= 32'h00000000;
  end else if (pipe.stall) begin
    r2_out <= r2_out;
  end else begin
    r2_out <= info.enable ? forward_rs2 : 32'h00000000;
  end
end

// Dff
always_ff @ (posedge clk) begin
  if (rst) begin
    info_ff <= 0;
  end else if (pipe.flush) begin
    info_ff <= 0;
  end else if (pipe.stall) begin
    info_ff <= info_ff;
  end else begin
    info_ff <= info;
  end
end

endmodule

`endif
