`ifndef RV5STAGE_REGFILE
`define RV5STAGE_REGFILE

module regfile(
  input logic clk,
  input logic rst,

  input PipeControl pipe,

  input logic [4:0] r1_addr,
  output logic [31:0] r1_data,

  input logic [4:0] r2_addr,
  output logic [31:0] r2_data,

  input logic w_enable,
  input logic [4:0] w_addr,
  input logic [31:0] w_data
);

logic [31:0] regs [0:31];

always_ff @ (posedge clk) begin
  if (rst) begin
    r1_data <= 32'h00000000;
  end else if (pipe.flush) begin
    r1_data <= 32'h00000000;
  end else if (pipe.stall) begin
    r1_data <= r1_data;
  end else if (r1_addr == 5'b00000) begin
    r1_data <= 32'h00000000;
  end else if (w_enable && r1_addr == w_addr) begin
    r1_data <= w_data;
  end else begin
    r1_data <= regs[r1_addr];
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    r2_data <= 32'h00000000;
  end else if (pipe.flush) begin
    r2_data <= 32'h00000000;
  end else if (pipe.stall) begin
    r2_data <= r2_data;
  end else if (w_enable && r2_addr == w_addr) begin
    r2_data <= w_data;
  end else begin
    r2_data <= regs[r2_addr];
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    regs[0] <= 32'h00000000;
    regs[1] <= 32'h00000000;
    regs[2] <= 32'h00000000;
    regs[3] <= 32'h00000000;
    regs[4] <= 32'h00000000;
    regs[5] <= 32'h00000000;
    regs[6] <= 32'h00000000;
    regs[7] <= 32'h00000000;
    regs[8] <= 32'h00000000;
    regs[9] <= 32'h00000000;
    regs[10] <= 32'h00000000;
    regs[11] <= 32'h00000000;
    regs[12] <= 32'h00000000;
    regs[13] <= 32'h00000000;
    regs[14] <= 32'h00000000;
    regs[15] <= 32'h00000000;
    regs[16] <= 32'h00000000;
    regs[17] <= 32'h00000000;
    regs[18] <= 32'h00000000;
    regs[19] <= 32'h00000000;
    regs[20] <= 32'h00000000;
    regs[21] <= 32'h00000000;
    regs[22] <= 32'h00000000;
    regs[23] <= 32'h00000000;
    regs[24] <= 32'h00000000;
    regs[25] <= 32'h00000000;
    regs[26] <= 32'h00000000;
    regs[27] <= 32'h00000000;
    regs[28] <= 32'h00000000;
    regs[29] <= 32'h00000000;
    regs[30] <= 32'h00000000;
    regs[31] <= 32'h00000000;
  end else if (w_enable && w_addr != 5'b00000) begin
    regs[w_addr] <= w_data;
  end else begin
    regs[w_addr] <= regs[w_addr];
  end
end

endmodule

`endif
