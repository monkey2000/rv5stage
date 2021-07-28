`ifndef RV5STAGE_EXECUTE
`define RV5STAGE_EXECUTE

`include "src/rtl/common.sv"

module execute(
  input logic clk,
  input logic rst,
  input DecodeInfo info,
  input logic [31:0] rs1_data,
  input logic [31:0] rs2_data,
  output logic [31:0] alu_out,
  output logic [31:0] alu_out_ff,
  output DecodeInfo info_ff
);

logic [31:0] opr1, opr2;

assign opr1 = rs1_data;
assign opr2 = info.alu_src ? info.imm : rs2_data;

logic [31:0] out;

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

always_ff @ (posedge clk) begin
  if (rst) begin
    alu_out <= 32'h00000000;
  end else begin
    alu_out <= out;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    alu_out_ff <= 32'h00000000;
  end else begin
    alu_out_ff <= alu_out;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    info_ff <= 0;
  end else begin
    info_ff <= info;
  end
end

endmodule

`endif
