`ifndef L2CACHE_SV
`define L2CACHE_SV

`include "common.sv"

module l2cache #(
  parameter PORTS = 2,
  parameter PORT_WIDTH = $clog2(PORTS),
  parameter WIDTH = 128,
  parameter MASKW = $clog2(WIDTH / 8),
  parameter SIZE = 256 * 1024 * 8,  // 256 KiB
  parameter ADDR_WIDTH = 32,
  parameter BUS_WIDTH = 64
) (
  input logic clk,
  input logic rst,

  SystemBus.provider bus [PORTS-1:0]
);


// ====================
//        BRAM
// ====================
logic                   bram_r_en;
logic [ADDR_WIDTH-1:0]  bram_r_addr;
logic [WIDTH-1:0]       bram_r_data;

logic [MASKW-1:0]       bram_w_en;
logic [ADDR_WIDTH-1:0]  bram_w_addr;
logic [WIDTH-1:0]       bram_w_data;

bram #(
  .WIDTH(WIDTH),
  .DEPTH(SIZE / WIDTH)
) mem(
  .clk(clk),
  .ena(| bram_w_en),
  .enb(bram_r_en),
  .wea(bram_w_en),
  .addra(bram_w_addr),
  .addrb(bram_r_addr),
  .dia(bram_w_data),
  .dob(bram_r_data)
);

// ====================
//     Handle read
// ====================
logic [PORTS-1:0] r_pri [PORTS-1:0];
logic [PORTS-1:0] r_valid;
logic [PORT_WIDTH-1:0] r_port_sel, r_port_sel_ff;

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign r_valid[i] = bus[i].rw_valid && (!bus[i].we);
  end
endgenerate

typedef enum {
  READ_IDLE = 0,
  READ_OPER,
  READ_RESP
} read_stat_t;
read_stat_t read_stat, read_stat_next;

always_ff @ (posedge clk) begin
  if (rst) begin
    for (integer i = 0; i < PORTS; i = i + 1) r_pri[i] <= (PORT_WIDTH'b1 << i);
  end if (read_stat == READ_OPER) begin
    for (integer i = 0; i < PORTS; i = i + 1) r_pri[i] <= {(PORT_WIDTH'b1 << i), (PORT_WIDTH'b1 << i)} >> r_port_sel_ff;
  end
end

// Port Selection
logic [PORTS-1:0] current_r_pri = 0;
always_comb begin
  current_r_pri = 0;
  r_port_sel = 0;
  for (integer i = 0; i < PORTS; i = i + 1) begin
    r_port_sel = (r_valid[i] && current_r_pri < r_pri[i]) ? i : r_port_sel;
    current_r_pri = (r_valid[i] && current_r_pri < r_pri[i]) ? r_pri[i] : current_r_pri;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    r_port_sel_ff <= 0;
  end else if (read_stat == READ_IDLE) begin
    r_port_sel_ff <= r_port_sel;
  end
end

// Operate RAM
always_comb begin
  // Defaults not to operate
  bram_r_en = 0;
  bram_r_addr = 0;

  if (read_stat == READ_OPER) begin
    bram_r_en = 1;
    bram_r_addr = bus[r_port_sel_ff].rw_addr
  end
end

// State Machine
always_comb begin
  unique case (read_stat)
  READ_IDLE:
    if (| r_valid) read_stat_next = READ_OPER;
    else read_stat_next = READ_IDLE;
  READ_OPER:
    read_stat_next = READ_RESP;
  READ_RESP:
    read_stat_next = READ_IDLE;
  default:
    read_stat_next = READ_IDLE;
  endcase
end

always_ff @ (posedge clk) begin
  if (rst) begin
    read_stat <= READ_IDLE;
  end else begin
    read_stat <= read_stat_next;
  end
end

// ====================
//     Handle write
// ====================
logic [PORTS-1:0] w_pri [PORTS-1:0];
logic [PORTS-1:0] w_valid;
logic [PORT_WIDTH-1:0] w_port_sel, w_port_sel_ff;

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign w_valid[i] = bus[i].rw_valid && (bus[i].we);
  end
endgenerate

typedef enum {
  WRITE_IDLE = 0,
  WRITE_BROADCAST,
  WRITE_OPER,
  WRITE_RESP
} write_stat_t;
write_stat_t write_stat, write_stat_next;

always_ff @ (posedge clk) begin
  if (rst) begin
    for (integer i = 0; i < PORTS; i = i + 1) w_pri[i] <= (PORT_WIDTH'b1 << i);
  end if (write_stat == WRITE_OPER) begin
    for (integer i = 0; i < PORTS; i = i + 1) w_pri[i] <= {(PORT_WIDTH'b1 << i), (PORT_WIDTH'b1 << i)} >> w_port_sel_ff;
  end
end

// Port Selection
logic [PORTS-1:0] current_w_pri = 0;
always_comb begin
  current_w_pri = 0;
  w_port_sel = 0;
  for (integer i = 0; i < PORTS; i = i + 1) begin
    w_port_sel = (w_valid[i] && current_w_pri < w_pri[i]) ? i : w_port_sel;
    current_w_pri = (w_valid[i] && current_w_pri < w_pri[i]) ? w_pri[i] : current_w_pri;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    w_port_sel_ff <= 0;
  end else if (read_stat == READ_IDLE) begin
    w_port_sel_ff <= w_port_sel;
  end
end

// Broadcast
logic [PORTS-1:0] broadcast_ready;
logic [PORTS-1:0] broadcast_board;

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign broadcast_ready[i] = bus[i].inv_ready;
  end
endgenerate

always_comb begin
  // Defaults not to broadcast
  for (integer i = 0; i < PORTS; i = i + 1) begin
    bus[i].inv_valid = 0;
    bus[i].inv_addr = 0;
  end

  if (write_stat == WRITE_BROADCAST) begin
    for (integer i = 0; i < PORTS; i = i + 1) begin
      bus[i].inv_valid = !broadcast_board[i];
      bus[i].inv_addr = bus[w_port_sel_ff].rw_addr;
    end
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    broadcast_board <= 0;
  end else if (write_stat == WRITE_BROADCAST) begin
    broadcast_board <= broadcast_board | broadcast_ready;
  end else begin
    broadcast_board <= 0;
  end
end

// Operate RAM
always_comb begin
  // Defaults not to operate
  bram_w_en = 0;
  bram_w_addr = 0;
  bram_w_data = 0;

  if (read_stat == WRITE_OPER) begin
    bram_w_en = bus[w_port_sel_ff].w_mask;
    bram_w_addr = bus[w_port_sel_ff].rw_addr;
    bram_w_data = bus[w_port_sel_ff].wdata;
  end
end

// State Machine
always_comb begin
  unique case (write_stat)
  WRITE_IDLE:
    if (| w_valid) write_stat_next = WRITE_OPER;
    else write_stat_next = WRITE_IDLE;
  WRITE_OPER:
    if (bus[w_port_sel].w_ce) write_stat_next = WRITE_BROADCAST;
    else write_stat_next = WRITE_RESP;
  WRITE_BROADCAST:
    if (broadcast_board == {PORTS{1'b1}}) write_stat_next = WRITE_RESP;
    else write_stat_next = WRITE_BROADCAST;
  WRITE_RESP:
    write_stat_next = WRITE_IDLE;
  default:
    write_stat_next = WRITE_IDLE;
  endcase
end

// ====================
//  Handle rw response
// ====================
generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign bus[i].r_data = bram_r_data;
  end
endgenerate

// We use only 1 comb block to avoid multidriven
always_comb begin
  // Defaults not to send any response
  for (integer i = 0; i < PORTS; i = i + 1) begin
    bus[i].rw_ready = 0;
  end

  if (read_stat == READ_RESP) begin
    bus[r_port_sel_ff].rw_ready = 1;
  end

  if (write_stat == WRITE_RESP) begin
    bus[w_port_sel_ff].rw_ready = 1;
  end
end

endmodule

`endif // L2CACHE_SV
