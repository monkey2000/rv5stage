`include "common.sv"

module snoopy_rocache #(
  parameter WIDTH = 128,
  parameter MASKW = WIDTH / 8,
  parameter SIZE = 4 * 1024 * 8,    // 4 KiB
  parameter DEPTH = SIZE / WIDTH,
  parameter ADDR_WIDTH = 32,
  parameter SPECULATE_BRAM_OPERATION = 1'b0
) (
  input   logic clk,
  input   logic rst,

  input   logic valid,
  output  logic ready,
  input   logic [ADDR_WIDTH-1:0] speculate_addr,
  input   logic [ADDR_WIDTH-1:0] addr,
  input   logic [MASKW-1:0] wmask,
  input   logic [WIDTH-1:0] wdata,
  output  logic [WIDTH-1:0] rdata,
  input   logic we,
  input   logic ce,

  SystemBus.user bus
);

parameter IDX_LSB_POS     = $clog2(WIDTH / 8);
parameter TAG_LSB_POS     = $clog2(SIZE / 8);
parameter TAG_WIDTH       = ADDR_WIDTH - TAG_LSB_POS;
parameter MEM_ADDR_WIDTH  = $clog2(DEPTH);
parameter DATA_LINE_WIDTH = WIDTH;
parameter TAG_LINE_WIDTH  = TAG_WIDTH;

logic [DEPTH-1:0]           valid_ram;
logic [MEM_ADDR_WIDTH-1:0]  valid_ram_r_addr;
logic                       valid_ram_r_data;

logic                       valid_ram_we1;
logic [MEM_ADDR_WIDTH-1:0]  valid_ram_w1_addr;
logic                       valid_ram_w1_data;
logic                       valid_ram_we2;
logic [MEM_ADDR_WIDTH-1:0]  valid_ram_w2_addr;
logic                       valid_ram_w2_data;

logic [MASKW-1:0]           data_ram_w_en;
logic data_ram_r_en;
logic [MEM_ADDR_WIDTH-1:0]  data_ram_w_addr;
logic [MEM_ADDR_WIDTH-1:0]  data_ram_r_addr;
logic [DATA_LINE_WIDTH-1:0] data_ram_w_data;
logic [DATA_LINE_WIDTH-1:0] data_ram_r_data;

logic tag_ram_rw_wen;
logic [MEM_ADDR_WIDTH-1:0]  tag_ram_rw_addr;
logic [MEM_ADDR_WIDTH-1:0]  tag_ram_r_addr;
logic [TAG_LINE_WIDTH-1:0]  tag_ram_rw_wdata;
logic [TAG_LINE_WIDTH-1:0]  tag_ram_rw_rdata;
logic [TAG_LINE_WIDTH-1:0]  tag_ram_r_data;

typedef enum {
  REFILL_IDLE = 0,
  REFILL_BUS,
  REFILL_OPER
} refill_stat_t;

refill_stat_t refill_stat, refill_stat_next;

typedef enum {
  WRITE_IDLE = 0,
  WRITE_BUS,
  WRITE_RESP
} write_stat_t;

write_stat_t write_stat, write_stat_next;

typedef enum {
  INV_IDLE = 0,
  INV_PENDING,
  INV_OPER
} inv_stat_t;

inv_stat_t inv_stat, inv_stat_next;

bram #(
  .WIDTH(DATA_LINE_WIDTH),
  .DEPTH(DEPTH)
) data_ram (
  .clk(clk),
  .ena(| data_ram_w_en),
  .enb(data_ram_r_en),
  .wea(data_ram_w_en),
  .addra(data_ram_w_addr),
  .addrb(data_ram_r_addr),
  .dia(data_ram_w_data),
  .dob(data_ram_r_data)
);

lutram #(
  .WIDTH(TAG_LINE_WIDTH),
  .DEPTH(DEPTH)
) tag_ram (
  .clk(clk),
  .we(tag_ram_rw_wen),
  .a(tag_ram_rw_addr),
  .dpra(tag_ram_r_addr),
  .di(tag_ram_rw_wdata),
  .spo(tag_ram_rw_rdata),
  .dpo(tag_ram_r_data)
);

// Valid RAM
assign valid_ram_r_data = valid_ram[valid_ram_r_addr];
always_ff @ (posedge clk) begin
  if (rst) begin
    valid_ram <= 0;
  end else begin
    if (valid_ram_we1) valid_ram[valid_ram_w1_addr] <= valid_ram_w1_data;
    if (valid_ram_we2) valid_ram[valid_ram_w2_addr] <= valid_ram_w2_data;
  end
end

// ====================
//     Handle read
// ====================

// Read
logic read_hit;
logic [ADDR_WIDTH-1:0]  refill_addr;
logic [WIDTH-1:0]       refill_data;


generate

if (SPECULATE_BRAM_OPERATION == 1'b0) begin

// Operate RAMs
always_comb begin
  // Defaults not to read or write
  tag_ram_rw_wen = 0;
  tag_ram_rw_addr = 0;
  tag_ram_rw_wdata = 0;

  data_ram_r_en = 0;
  data_ram_r_addr = 0;
  data_ram_w_en = 0;
  data_ram_w_addr = 0;
  data_ram_w_data = 0;

  valid_ram_r_addr = 0;
  valid_ram_we1 = 0;
  valid_ram_w1_addr = 0;
  valid_ram_w1_data = 1;

  if (valid && !we && refill_stat == REFILL_IDLE) begin
    // If we're not writing, and we're not in refill, then we're reading
    tag_ram_rw_addr = addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];

    data_ram_r_en = 1;
    data_ram_r_addr = addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];

    valid_ram_r_addr = addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
  end else if (refill_stat == REFILL_OPER) begin
    // If refill is in progress
    tag_ram_rw_wen = 1;
    tag_ram_rw_addr = refill_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    tag_ram_rw_wdata = refill_addr[TAG_LSB_POS +: TAG_WIDTH];

    data_ram_w_en = {MASKW{1'b1}};
    data_ram_w_addr = refill_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    data_ram_w_data = refill_data;

    valid_ram_we1 = 1;
    valid_ram_w1_addr = refill_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    valid_ram_w1_data = 1;
  end
end

// Check hit or miss
always_comb begin
  // Hit if tag matches and block is valid
  read_hit = (addr[TAG_LSB_POS +: TAG_WIDTH] == tag_ram_rw_rdata && valid_ram_r_data);
end

// Read response
always_comb begin
  rdata = data_ram_r_data;
end

end else begin // SPECULATE_BRAM_OPERATION == 1'b1

// Speculatively operate Data RAM
always_comb begin
  data_ram_r_en = 1;
  data_ram_r_addr = speculate_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
end

// Operate RAMs
always_comb begin
  // Defaults not to read or write
  tag_ram_rw_wen = 0;
  tag_ram_rw_addr = 0;
  tag_ram_rw_wdata = 0;

  data_ram_w_en = 0;
  data_ram_w_addr = 0;
  data_ram_w_data = 0;

  valid_ram_r_addr = 0;
  valid_ram_we1 = 0;
  valid_ram_w1_addr = 0;
  valid_ram_w1_data = 1;

  if (valid && !we && refill_stat == REFILL_IDLE) begin
    // If we're not writing, and we're not in refill, then we're reading
    tag_ram_rw_addr = addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];

    valid_ram_r_addr = addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
  end else if (refill_stat == REFILL_OPER) begin
    // If refill is in progress
    tag_ram_rw_wen = 1;
    tag_ram_rw_addr = refill_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    tag_ram_rw_wdata = refill_addr[TAG_LSB_POS +: TAG_WIDTH];

    data_ram_w_en = {MASKW{1'b1}};
    data_ram_w_addr = refill_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    data_ram_w_data = refill_data;

    valid_ram_we1 = 1;
    valid_ram_w1_addr = refill_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    valid_ram_w1_data = 1;
  end
end

// Check hit or miss
always_comb begin
  // Hit if tag matches and block is valid
  read_hit = (addr[TAG_LSB_POS +: TAG_WIDTH] == tag_ram_rw_rdata && valid_ram_r_data);
end

refill_stat_t refill_stat_last;

always_ff @ (posedge clk) begin
  if (rst) begin
    refill_stat_last <= REFILL_IDLE;
  end else begin
    refill_stat_last <= refill_stat;
  end
end

// Read response
always_ff @ (posedge clk) begin
  if (rst) begin
    rdata <= 0;
  end else if (refill_stat_last == REFILL_OPER) begin
    rdata <= refill_data;
  end else begin
    rdata <= data_ram_r_data;
  end
end

end

endgenerate

// refill FSM
always_comb begin
  unique case (refill_stat)
  REFILL_IDLE: begin
    if (valid && !we && !read_hit && inv_stat == INV_IDLE) refill_stat_next = REFILL_BUS;
    else refill_stat_next = REFILL_IDLE;
  end
  REFILL_BUS: begin
    if (bus.rw_ready) refill_stat_next = REFILL_OPER;
    else refill_stat_next = REFILL_BUS;
  end
  REFILL_OPER: begin
    refill_stat_next = REFILL_IDLE;
  end
  default: refill_stat_next = REFILL_IDLE;
  endcase
end

always_ff @ (posedge clk) begin
  if (rst) begin
    refill_stat <= REFILL_IDLE;
  end else begin
    refill_stat <= refill_stat_next;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    refill_addr <= 0;
  end else if (refill_stat == REFILL_IDLE && refill_stat_next == REFILL_BUS) begin
    refill_addr <= addr;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    refill_data <= 0;
  end else if (refill_stat == REFILL_BUS && refill_stat_next == REFILL_OPER) begin
    refill_data <= bus.r_data;
  end
end

// ====================
//     Handle write
// ====================

// write FSM
always_comb begin
  unique case (write_stat)
  WRITE_IDLE: begin
    if (valid && we) write_stat_next = WRITE_BUS;
    else write_stat_next = WRITE_IDLE;
  end
  WRITE_BUS: begin
    if (bus.rw_ready) write_stat_next = WRITE_RESP;
    else write_stat_next = WRITE_BUS;
  end
  WRITE_RESP: begin
    write_stat_next = WRITE_IDLE;
  end
  endcase
end

always_ff @ (posedge clk) begin
  if (rst) begin
    write_stat <= WRITE_IDLE;
  end else begin
    write_stat <= write_stat_next;
  end
end

// ====================
//   Common for R/W
// ====================
always_comb begin
  // Defaults not to send ready
  ready = 0;

  if (valid && !we) begin
    if (refill_stat == REFILL_IDLE && read_hit) begin
      ready = 1;
    end
  end else if (valid && we) begin
    if (write_stat == WRITE_RESP) begin
      ready = 1;
    end
  end
end

always_comb begin
  // Defaults not to send bus request
  bus.rw_valid = 0;
  bus.rw_addr = 0;
  bus.rw_we = 0;
  bus.w_mask = 0;
  bus.w_data = 0;
  bus.w_ce = 0;

  if (refill_stat == REFILL_BUS) begin
    bus.rw_valid = 1;
    bus.rw_addr = refill_addr;
    bus.rw_we = 0;
  end else if (write_stat == WRITE_BUS) begin
    bus.rw_valid = 1;
    bus.rw_addr = addr;
    bus.rw_we = 1;
    bus.w_mask = wmask;
    bus.w_data = wdata;
    bus.w_ce = 1;
  end
end

// ====================
//  Handle invalidate
// ====================
// invalidate FSM
always_comb begin
  unique case (inv_stat)
  INV_IDLE: begin
    if (bus.inv_valid) inv_stat_next = INV_PENDING;
    else inv_stat_next = INV_IDLE;
  end
  INV_PENDING: begin
    if (refill_stat == REFILL_IDLE) inv_stat_next = INV_OPER;
    else inv_stat_next = INV_PENDING;
  end
  INV_OPER: begin
    inv_stat_next = INV_IDLE;
  end
  default: inv_stat_next = INV_IDLE;
  endcase
end

always_ff @ (posedge clk) begin
  if (rst) begin
    inv_stat <= INV_IDLE;
  end else begin
    inv_stat <= inv_stat_next;
  end
end

// Operate RAM
always_comb begin
  // Defaults not to operate
  tag_ram_r_addr = 0;

  valid_ram_we2 = 0;
  valid_ram_w2_addr = 0;
  valid_ram_w2_data = 0;

  if (inv_stat == INV_OPER) begin
    tag_ram_r_addr = bus.inv_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    valid_ram_w2_addr = bus.inv_addr[IDX_LSB_POS +: MEM_ADDR_WIDTH];
    valid_ram_we2 = (tag_ram_r_data == bus.inv_addr[TAG_LSB_POS +: TAG_WIDTH]);
  end
end

// Inv response
always_comb begin
  // Defaults not to send response
  bus.inv_ready = 0;

  if (inv_stat == INV_OPER) begin
    bus.inv_ready = 1;
  end
end

endmodule
