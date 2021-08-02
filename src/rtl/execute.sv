`ifndef RV5STAGE_EXECUTE
`define RV5STAGE_EXECUTE

`include "src/rtl/common.sv"

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
  output logic pc_w_enable,
  output logic [31:0] new_pc,
  output DecodeInfo info_ff
);

assign req.stall_req = 1'b0;

logic [31:0] opr1, opr2;

logic forward_opr1_from_exe = info.enable && info_ff.enable && info_ff.rd_valid && info.rs1 == info_ff.rd;
logic forward_opr2_from_exe = info.enable && info_ff.enable && info_ff.rd_valid && info.rs2 == info_ff.rd;

logic forward_opr1_from_mem = info.enable && mem_info.enable && mem_info.rd_valid && info.rs1 == mem_info.rd;
logic forward_opr2_from_mem = info.enable && mem_info.enable && mem_info.rd_valid && info.rs2 == mem_info.rd;

assign opr1 = forward_opr1_from_exe ? alu_out : forward_opr1_from_mem ? mem_out : rs1_data;
assign opr2 = info.alu_src ? info.imm : forward_opr2_from_exe ? alu_out : forward_opr2_from_mem ? mem_out : rs2_data;

logic logic_out;

logic [31:0] out;

// Logic
always_comb begin
  case (info.funct3)
  3'b000: begin
    logic_out = (opr1 == opr2);
  end
  3'b001: begin
    logic_out = (opr1 != opr2);
  end
  default: begin
    logic_out = 1'b0;
  end
  endcase
end

always_comb begin
  new_pc = info.pc + info.imm;
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
  default: begin
    out = 32'h00000000;
  end
  endcase
end

always_comb begin
  pc_w_enable = (info.branch && logic_out);
  req.flush_req = (info.branch && logic_out) ? 4'b0110 : 4'b0000;
end

always_ff @ (posedge clk) begin
  if (rst) begin
    alu_out <= 32'h00000000;
  end else if (pipe.stall) begin
    alu_out <= alu_out;
  end else if (pipe.flush) begin
    alu_out <= 32'h00000000;
  end else begin
    alu_out <= info.enable ? out : 32'h00000000;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    info_ff <= 0;
  end else if (pipe.stall) begin
    info_ff <= info_ff;
  end else if (pipe.flush) begin
    info_ff <= 0;
  end else begin
    info_ff <= info;
  end
end

endmodule

`endif
