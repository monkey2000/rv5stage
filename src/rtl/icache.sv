`ifndef RV5STAGE_ICACHE
`define RV5STAGE_ICACHE

`include "common.sv"

module icache(
  input logic clk,
  input logic rst,
  output PipeRequest req,
  input PipeControl pc_pipe,
  input PipeControl if_id_pipe,
  input logic [31:0] addr,
  input logic [31:0] addr_ff,
  output logic [31:0] inst,
  SystemBus.user bus,
  output logic error
);

logic icache_ready;
logic [127:0] icache_rdata;

snoopy_rocache #(.SPECULATE_BRAM_OPERATION(1'b0)) icache (
  .clk(clk),
  .rst(rst),
  .valid(!error),
  .ready(icache_ready),
  .speculate_addr(0),
  .addr(addr),
  .rdata(icache_rdata),
  .wdata(0),
  .wmask(0),
  .we(0),
  .ce(0),
  .bus(bus)
);

// Valid range: [0x80000000, 0x80040000) 256KiB
assign error = addr[1:0] != 2'b00 || addr >= 32'h80040000 || addr < 32'h80000000;

logic stall_pending, stall_ff;
logic [127:0] icache_data_ff;

always_ff @(posedge clk) begin
  if (rst) begin
    icache_data_ff <= 0;
  end else if (pc_pipe.stall && !stall_ff) begin
    icache_data_ff <= icache_rdata;
  end else begin
    icache_data_ff <= icache_data_ff;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    stall_ff <= 0;
  end else if (pc_pipe.stall) begin
    stall_ff <= 1;
  end else begin
    stall_ff <= 0;
  end
end

always_ff @(posedge clk) begin
  if (rst) begin
    inst <= 32'h00000000;
  end else if (if_id_pipe.flush) begin
    inst <= 32'h00000000;
  end else if (if_id_pipe.stall) begin
    inst <= inst;
  end else begin
    inst <= stall_ff ? icache_data_ff[addr_ff[3:2] * 32 +: 32] : icache_rdata[addr_ff[3:2] * 32 +: 32];
  end
end

assign req.stall_req = !icache_ready;
assign req.flush_req = 4'b0000;

endmodule

`endif
