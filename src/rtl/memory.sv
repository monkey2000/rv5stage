`ifndef RV5STAGE_MEMORY
`define RV5STAGE_MEMORY

`include "common.sv"

module memory(
  input logic clk,
  input logic rst,
  output PipeRequest req,
  input DecodeInfo info,
  input logic [31:0] addr,
  input logic [31:0] data,
  output logic [31:0] mem_out,
  output DecodeInfo info_ff,

  SystemBus.user bus
);

logic error;
assign error = addr[1:0] != 2'b00 || addr >= 32'h80040000 || addr < 32'h80000000;

logic dcache_valid;
logic dcache_ready;
logic dcache_we;
logic [127:0] dcache_rdata;
logic [15:0] dcache_wmask;
logic [127:0] dcache_wdata;

snoopy_rocache dcache(
  .clk(clk),
  .rst(rst),
  .valid(dcache_valid),
  .ready(dcache_ready),
  .addr(addr),
  .rdata(dcache_rdata),
  .wdata(dcache_wdata),
  .wmask(dcache_wmask),
  .we(dcache_we),
  .ce(1),
  .bus(bus)
);

logic [15:0] wmask;
always_comb begin
  unique case (info.funct3)
  3'b000: begin
    wmask = 16'h0001 << addr[3:0];
  end
  3'b001: begin
    wmask = 16'h0002 << addr[3:0];
  end
  3'b010: begin
    wmask = 16'h0004 << addr[3:0];
  end
  default: begin
    wmask = 0;
  end
  endcase
end

always_comb begin
  // Defaults not to send request
  dcache_valid = 0;
  dcache_we = 0;
  dcache_wmask = 0;
  dcache_wdata = 0;

  if (info.mem_read) begin
    dcache_valid = 1;
    dcache_we = 0;
    dcache_wmask = 0;
    dcache_wdata = 0;
  end else if (info.mem_write) begin
    dcache_valid = 1;
    dcache_we = 1;
    dcache_wmask = wmask;
    dcache_wdata = data << (addr[3:0] * 8);
  end
end

logic [31:0] addr_ff;
logic [31:0] mem_rdata;

always_ff @ (posedge clk) begin
  if (rst) begin
    addr_ff <= 0;
  end else begin
    addr_ff <= addr;
  end
end

always_comb begin
  unique case (info_ff.funct3)
  3'b000: begin
    mem_rdata = {{24{dcache_rdata[addr_ff[3:0] * 8 + 7]}}, dcache_rdata[addr_ff[3:0] * 8 +: 8]};
  end
  3'b001: begin
    mem_rdata = {{16{dcache_rdata[addr_ff[3:1] * 16 + 15]}}, dcache_rdata[addr_ff[3:1] * 16 +: 16]};
  end
  3'b010: begin
    mem_rdata = dcache_rdata[addr_ff[3:2] * 32 +: 32];
  end
  3'b100: begin
    mem_rdata = {{24{1'b0}}, dcache_rdata[addr_ff[3:0] * 8 +: 8]};
  end
  3'b101: begin
    mem_rdata = {{16{1'b0}}, dcache_rdata[addr_ff[3:1] * 16 +: 16]};
  end
  default: begin
    mem_rdata = 0;
  end
  endcase

  mem_out = info_ff.mem_to_reg ? mem_rdata : addr_ff;
end

always_ff @ (posedge clk) begin
  if (rst) begin
    info_ff <= 0;
  end else begin
    info_ff <= info;
  end
end

assign req.stall_req = !dcache_ready;
assign req.flush_req = 4'b0000;

endmodule

`endif
