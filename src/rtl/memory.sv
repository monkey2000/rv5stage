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
  output DecodeInfo info_ff
);

assign req.stall_req = 1'b0;
assign req.flush_req = 4'b0000;

logic r_enable, w_enable;
logic [31:0] r_addr, r_data, w_addr, w_data;

dcache dcache(.clk(clk), .rst(rst), .r_enable(r_enable), .r_addr(r_addr), .r_data(r_data), .w_enable(w_enable), .w_addr(w_addr), .w_data(w_data));

always_comb begin
  if (info.mem_read) begin
    r_enable = 1'b1;
    r_addr = addr;
  end else if (info.mem_write) begin
    r_enable = 1'b1;
    r_addr = addr;
  end else begin
    r_enable = 1'b0;
    r_addr = 32'h00000000;
  end
end

logic [31:0] read_aligned, read_extended;
assign read_aligned = (r_data >> (8 * addr[1:0]));

always_comb begin
  case (info.funct3)
  3'b000: read_extended = {{24{read_aligned[7]}}, read_aligned[7:0]};        // LB
  3'b001: read_extended = {{16{read_aligned[15]}}, read_aligned[15:0]};      // LH
  3'b010: read_extended = read_aligned;                                      // LW
  3'b100: read_extended = {{24{1'b0}}, read_aligned[7:0]};                   // LBU
  3'b101: read_extended = {{16{1'b0}}, read_aligned[15:0]};                  // LWU
  default: read_extended = 32'h00000000;
  endcase
end

assign w_enable = info.mem_write;
assign w_addr = info.mem_write ? addr : 32'h00000000;

logic [31:0] w_mask;

always_comb begin
  case (info.funct3)
  3'b000: begin
    w_mask = 32'h000000ff << (addr[1:0] * 8);
    w_data = (r_data & ~w_mask) | ((data & 32'h000000ff) << (addr[1:0] * 8));
  end
  3'b001: begin
    w_mask = 32'h0000ffff << (addr[1:0] * 8);
    w_data = (r_data & ~w_mask) | ((data & 32'h0000ffff) << (addr[1:0] * 8));
  end
  3'b010: begin
    w_mask = 32'hffffffff;
    w_data = data;
  end
  default: begin
    w_mask = 32'h00000000;
    w_data = r_data;
  end
  endcase
end

always_ff @ (posedge clk) begin
  if (rst) begin
    mem_out <= 32'h00000000;
  // end else if (pipe.stall) begin
  //   mem_out <= mem_out;
  // end else if (pipe.flush) begin
  //   mem_out <= 32'h00000000;
  end else begin
    mem_out <= info.mem_read ? read_extended : addr;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    info_ff <= 0;
  // end else if (pipe.stall) begin
  //   info_ff <= info_ff;
  // end else if (pipe.flush) begin
  //   info_ff <= 0;
  end else begin
    info_ff <= info;
  end
end

endmodule

`endif
