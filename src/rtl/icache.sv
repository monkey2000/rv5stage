`ifndef RV5STAGE_ICACHE
`define RV5STAGE_ICACHE

`include "common.sv"

module icache(
  input logic clk,
  input logic rst,
  output PipeRequest req,
  input PipeControl pipe,
  input logic [31:0] addr,
  input logic [31:0] addr_ff,
  output logic [31:0] inst,
  SystemBus.user bus,
  output logic error
);

logic icache_ready;
logic [127:0] icache_rdata;

snoopy_rocache icache(
  .clk(clk),
  .rst(rst),
  .valid(!error),
  .ready(icache_ready),
  .addr(addr),
  .rdata(icache_rdata),
  .wdata(0),
  .wmask(0),
  .we(0),
  .ce(0),
  .bus(bus)
)

// Valid range: [0x80000000, 0x80040000) 256KiB
assign error = addr[1:0] != 2'b00 || addr >= 32'h80040000 || addr < 32'h80000000;

always_ff @(posedge clk) begin
  if (rst) begin
    inst <= 32'h00000000;
  end else if (pipe.flush) begin
    inst <= 32'h00000000;
  end else if (pipe.stall) begin
    inst <= inst;
  end else begin
    inst <= icache_rdata[addr_ff[3:2] * 32 +: 32];
  end
end

assign req.stall_req = !icache_ready;
assign req.flush_req = 4'b0000;

endmodule

`endif
