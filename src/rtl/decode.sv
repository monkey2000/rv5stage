`ifndef RV5STAGE_DECODE
`define RV5STAGE_DECODE

`include "src/rtl/common.sv"

module decode(
  input logic clk,
  input logic rst,
  input FetchInfo fetch_info,
  output logic error,
  output DecodeInfo info,
  output DecodeInfo info_ff
);

logic [31:0] pc;
logic [31:0] inst;

assign pc = fetch_info.pc;
assign inst = fetch_info.inst;

logic [6:0] opcode;
logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;

logic [2:0] funct3;
logic [6:0] funct7;

logic reg_write;
logic alu_src;
logic pc_src;
logic mem_read;
logic mem_write;
logic mem_to_reg;

assign reg_write = info.reg_write;
assign alu_src = info.alu_src;
assign pc_src = info.pc_src;
assign mem_read = info.mem_read;
assign mem_write = info.mem_write;
assign mem_to_reg = info.mem_to_reg;

assign opcode = inst[6:0];
assign rd = inst[11:7];
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

logic [31:0] imm_i, imm_s, imm_b;

assign imm_i = {{21{inst[31]}}, inst[30:20]};
assign imm_s = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign imm_b = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

always_comb begin
  //                                                               isarith,regw,alusrc,pcsrc,memr,memw,mem2reg
  case (opcode)
    7'b0010011: begin // I type arithmetic
      info = '{1'b1, pc, opcode, rd, rs1, rs2, imm_i, funct3, funct7, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0};
      error = 1'b0;
    end
    7'b0110011: begin // R type arithmetic
      info = '{1'b1, pc, opcode, rd, rs1, rs2, imm_i, funct3, funct7, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
      error = 1'b0;
    end
    7'b0000011: begin // Load
      info = '{1'b1, pc, opcode, rd, rs1, rs2, imm_i, funct3, funct7, 0'b1, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1};
      error = 1'b0;
    end
    7'b0100011: begin // Store
      info = '{1'b1, pc, opcode, rd, rs1, rs2, imm_s, funct3, funct7, 0'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
      error = 1'b0;
    end
    default: begin
      info = 0;
      error = 1'b1;
    end
  endcase
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
