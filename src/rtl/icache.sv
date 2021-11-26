`ifndef RV5STAGE_ICACHE
`define RV5STAGE_ICACHE

`include "common.sv"

module icache(
  input logic clk,
  input logic rst,
  input PipeControl pipe,
  input logic [31:0] addr,
  output logic [31:0] inst,
  output logic error
);

// 4KB Inst Memory
// Depth = 1024
// Data Width = 4 Bytes
logic [31:0] inst_mem [0:1023];

// Mapped to [0x0000, 0x1000)
assign error = addr[1:0] != 2'b00 || addr >= 32'h1000;

initial begin
  $readmemh("data/icache.dat", inst_mem);
end

logic [31:0] next_inst;
assign next_inst = inst_mem[addr[11:2]];

always_ff @(posedge clk) begin
  if (rst) begin
    inst <= 32'h00000000;
  end else if (pipe.stall) begin
    inst <= inst;
  end else if (pipe.flush) begin
    inst <= 32'h00000000;
  end else begin
    inst <= next_inst;
  end
end

endmodule

`endif
