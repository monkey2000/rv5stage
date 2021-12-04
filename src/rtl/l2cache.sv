`ifndef L2CACHE_SV
`define L2CACHE_SV

`include "common.sv"

module l2cache #(
  parameter PORTS = 2,
  parameter PORT_WIDTH = $clog2(PORTS),
  parameter WIDTH = 128,
  parameter MASKW = WIDTH / 8,
  parameter SIZE = 256 * 1024 * 8,  // 256 KiB
  parameter ADDR_WIDTH = 32,
  parameter string INIT_FILE = ""
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

parameter BRAM_ADDR_WIDTH = $clog2(SIZE / WIDTH);
parameter BRAM_ADDR_LSB   = $clog2(WIDTH / 8);

bram #(
  .WIDTH(WIDTH),
  .DEPTH(SIZE / WIDTH),
  .INIT_FILE(INIT_FILE)
) mem(
  .clk(clk),
  .ena(| bram_w_en),
  .enb(bram_r_en),
  .wea(bram_w_en),
  .addra(bram_w_addr[BRAM_ADDR_LSB +: BRAM_ADDR_WIDTH]),
  .addrb(bram_r_addr[BRAM_ADDR_LSB +: BRAM_ADDR_WIDTH]),
  .dia(bram_w_data),
  .dob(bram_r_data)
);

// ====================
//     Handle read
// ====================
logic [PORTS-1:0] r_pri [PORTS-1:0];
logic [PORTS-1:0] r_valid;
logic [PORT_WIDTH-1:0] r_port_sel [PORTS:0];
logic [PORT_WIDTH-1:0] r_port_sel_ff;

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign r_valid[i] = bus[i].rw_valid && (!bus[i].rw_we);
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
    for (integer i = 0; i < PORTS; i = i + 1)
      r_pri[i] <= ({{(PORTS-1){1'b0}}, {1'b1}} << i);
  end else if (read_stat == READ_OPER) begin
    for (integer i = 0; i < PORTS; i = i + 1)
      r_pri[i] <= ({{(PORTS-1){1'b0}}, {1'b1}} << (r_port_sel_ff - i[PORT_WIDTH-1:0]));
  end
end

// Port Selection
logic [PORTS-1:0] current_r_pri [PORTS:0];
always_comb begin
  r_port_sel[0] = 0;
  current_r_pri[0] = 0;
  for (integer i = 0; i < PORTS; i = i + 1) begin
    r_port_sel[i+1] = (r_valid[i] && current_r_pri[i] < r_pri[i]) ? i[PORT_WIDTH-1:0] : r_port_sel[i];
    current_r_pri[i+1] = (r_valid[i] && current_r_pri[i] < r_pri[i]) ? r_pri[i] : current_r_pri[i];
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    r_port_sel_ff <= 0;
  end else if (read_stat == READ_IDLE) begin
    r_port_sel_ff <= r_port_sel[PORTS];
  end
end

// Operate RAM
logic [ADDR_WIDTH-1:0] bus_rw_addr [PORTS-1:0];
generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign bus_rw_addr[i] = bus[i].rw_addr;
  end
endgenerate

always_comb begin
  // Defaults not to operate
  bram_r_en = 0;
  bram_r_addr = 0;

  if (read_stat == READ_OPER) begin
    bram_r_en = 1;
    bram_r_addr = bus_rw_addr[r_port_sel_ff];
  end
end

// State Machine
always_comb begin
  unique case (read_stat)
  READ_IDLE: begin
    if (| r_valid) read_stat_next = READ_OPER;
    else read_stat_next = READ_IDLE;
  end
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
logic [PORT_WIDTH-1:0] w_port_sel [PORTS:0];
logic [PORT_WIDTH-1:0] w_port_sel_ff;

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign w_valid[i] = bus[i].rw_valid && (bus[i].rw_we);
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
    for (integer i = 0; i < PORTS; i = i + 1)
      w_pri[i] <= ({{(PORTS-1){1'b0}}, {1'b1}} << i);
  end if (write_stat == WRITE_OPER) begin
    for (integer i = 0; i < PORTS; i = i + 1)
      w_pri[i] <= ({{(PORTS-1){1'b0}}, {1'b1}} << (w_port_sel_ff - i[PORT_WIDTH-1:0]));
  end
end

// Port Selection
logic [PORTS-1:0] current_w_pri [PORTS:0];
always_comb begin
  w_port_sel[0] = 0;
  current_w_pri[0] = 0;
  for (integer i = 0; i < PORTS; i = i + 1) begin
    w_port_sel[i+1] = (w_valid[i] && current_w_pri[i] < w_pri[i]) ? i[PORT_WIDTH-1:0] : w_port_sel[i];
    current_w_pri[i+1] = (w_valid[i] && current_w_pri[i] < w_pri[i]) ? w_pri[i] : current_w_pri[i];
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    w_port_sel_ff <= 0;
  end else if (read_stat == READ_IDLE) begin
    w_port_sel_ff <= w_port_sel[PORTS];
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

logic bus_inv_valid [PORTS-1:0];
logic [ADDR_WIDTH-1:0] bus_inv_addr [PORTS-1:0];

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign bus_inv_valid[i] = bus[i].inv_valid;
    assign bus_inv_addr[i] = bus[i].inv_addr;
  end
endgenerate

always_comb begin
  // Defaults not to broadcast
  for (integer i = 0; i < PORTS; i = i + 1) begin
    bus_inv_valid[i] = 0;
    bus_inv_addr[i] = 0;
  end

  if (write_stat == WRITE_BROADCAST) begin
    for (integer i = 0; i < PORTS; i = i + 1) begin
      bus_inv_valid[i] = !broadcast_board[i];
      bus_inv_addr[i] = bus_rw_addr[w_port_sel_ff];
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
logic [MASKW-1:0] bus_w_mask [PORTS-1:0];
logic [WIDTH-1:0] bus_w_data [PORTS-1:0];

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign bus_w_mask[i] = bus[i].w_mask;
    assign bus_w_data[i] = bus[i].w_data;
  end
endgenerate

always_comb begin
  // Defaults not to operate
  bram_w_en = 0;
  bram_w_addr = 0;
  bram_w_data = 0;

  if (read_stat == WRITE_OPER) begin
    bram_w_en = bus_w_mask[w_port_sel_ff];
    bram_w_addr = bus_rw_addr[w_port_sel_ff];
    bram_w_data = bus_w_data[w_port_sel_ff];
  end
end

// State Machine
logic bus_w_ce [PORTS-1:0];

generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign bus_w_ce[i] = bus[i].w_ce;
  end
endgenerate

always_comb begin
  unique case (write_stat)
  WRITE_IDLE:
    if (| w_valid) write_stat_next = WRITE_OPER;
    else write_stat_next = WRITE_IDLE;
  WRITE_OPER:
    if (bus_w_ce[w_port_sel[PORTS]]) write_stat_next = WRITE_BROADCAST;
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

logic bus_rw_ready [PORTS-1:0];
generate
  for (genvar i = 0; i < PORTS; i = i + 1) begin
    assign bus[i].rw_ready = bus_rw_ready[i];
  end
endgenerate

// We use only 1 comb block to avoid multidriven
always_comb begin
  // Defaults not to send any response
  for (integer i = 0; i < PORTS; i = i + 1) begin
    bus_rw_ready[i] = 0;
  end

  if (read_stat == READ_RESP) begin
    bus_rw_ready[r_port_sel_ff] = 1;
  end

  if (write_stat == WRITE_RESP) begin
    bus_rw_ready[w_port_sel_ff] = 1;
  end
end

endmodule

`endif // L2CACHE_SV
