// UART 8n1 controller
// Only TX is supported now

module uart_ctrl (
  input logic clk,
  input logic uart_clk8,
  input logic uart_clk,
  input logic rst,

  // These signals are under clock domain `clk`
  input logic valid,
  output logic ready,
  input logic [7:0] data,

  output logic uart_tx
);

logic uart_ready, uart_valid;
logic [7:0] uart_data;

// ====================
//     System half
// ====================

typedef enum {
  UART_SYS_IDLE = 0,
  UART_SYS_WAIT_RDY,
  UART_SYS_WAIT_FIN
} system_uart_stat_t;
system_uart_stat_t sys_stat, sys_stat_next;

always_comb begin
  ready = 0;
  uart_valid = 0;

  if (sys_stat == UART_SYS_IDLE) begin
    ready = valid;
  end

  if (sys_stat == UART_SYS_WAIT_RDY) begin
    uart_valid = 1;
  end
end

always_ff @ (posedge clk) begin
  if (rst) begin
    uart_data <= 0;
  end else if (sys_stat == UART_SYS_IDLE && valid) begin
    uart_data <= data;
  end else begin
    uart_data <= uart_data;
  end
end

always_comb begin
  unique case (sys_stat)
  UART_SYS_IDLE:
    if (valid) sys_stat_next = UART_SYS_WAIT_RDY;
    else sys_stat_next = UART_SYS_IDLE;
  UART_SYS_WAIT_RDY:
    if (uart_ready) sys_stat_next = UART_SYS_WAIT_FIN;
    else sys_stat_next = UART_SYS_WAIT_RDY;
  UART_SYS_WAIT_FIN:
    if (!uart_ready) sys_stat_next = UART_SYS_IDLE;
    else sys_stat_next = UART_SYS_WAIT_FIN;
  endcase
end

always_ff @ (posedge clk) begin
  if (rst) begin
    sys_stat <= UART_SYS_IDLE;
  end else begin
    sys_stat <= sys_stat_next;
  end
end

// ====================
//      UART half
// ====================

typedef enum {
  UART_TX_IDLE = 0,
  UART_TX_WAIT,
  UART_TX_RDY,
  UART_TX_FIN,
  UART_TX_START,
  UART_TX_OPER,
  UART_TX_STOP
} uart_tx_stat_t;

uart_tx_stat_t tx_stat, tx_stat_last, tx_stat_next;
logic [7:0] tx_buf;
logic [2:0] tx_cnt, tx_shift;

always_ff @ (posedge uart_clk8) begin
  if (rst) begin
    uart_ready <= 0;
  end else if (tx_stat == UART_TX_RDY) begin
    uart_ready <= 1;
  end else if (tx_stat == UART_TX_FIN) begin
    uart_ready <= 0;
  end
end

always_ff @ (posedge uart_clk8) begin
  if (rst) begin
    tx_shift <= 0;
  end else if (tx_stat == UART_TX_OPER) begin
    tx_shift <= tx_shift + {2'b00, (tx_cnt == 3'b111)};
  end else begin
    tx_shift <= 0;
  end
end

always_ff @ (posedge uart_clk8) begin
  if (rst) begin
    tx_cnt <= 0;
  end if (tx_stat == UART_TX_START || tx_stat == UART_TX_OPER || tx_stat == UART_TX_STOP) begin
    tx_cnt <= tx_cnt + 1;
  end else begin
    tx_cnt <= 0;
  end
end

always_ff @ (posedge uart_clk8) begin
  if (rst) begin
    tx_buf <= 0;
  end else if (tx_stat == UART_TX_WAIT) begin
    tx_buf <= uart_data;
  end else begin
    tx_buf <= tx_buf;
  end
end

always_comb begin
  uart_tx = 1;

  if (tx_stat == UART_TX_START) begin
    uart_tx = 0;
  end else if (tx_stat == UART_TX_OPER) begin
    uart_tx = tx_buf[tx_shift];
  end else if (tx_stat == UART_TX_STOP) begin
    uart_tx = 1;
  end
end

always_comb begin
  unique case (tx_stat)
  UART_TX_IDLE:
    if (uart_valid) tx_stat_next = UART_TX_WAIT;
    else tx_stat_next = UART_TX_IDLE;
  UART_TX_WAIT:
    tx_stat_next = UART_TX_RDY;
  UART_TX_RDY:
    if (!uart_valid) tx_stat_next = UART_TX_FIN;
    else tx_stat_next = UART_TX_RDY;
  UART_TX_FIN:
    tx_stat_next = UART_TX_START;
  UART_TX_START:
    if (tx_cnt == 3'b111) tx_stat_next = UART_TX_OPER;
    else tx_stat_next = UART_TX_START;
  UART_TX_OPER:
    if (tx_shift == 3'b111 && tx_cnt == 3'b111) tx_stat_next = UART_TX_STOP;
    else tx_stat_next = UART_TX_OPER;
  UART_TX_STOP:
    if (tx_cnt == 3'b111) tx_stat_next = UART_TX_IDLE;
    else tx_stat_next = UART_TX_STOP;
  default:
    tx_stat_next = UART_TX_IDLE;
  endcase
end

always_ff @ (posedge uart_clk8) begin
  if (rst) begin
    tx_stat <= UART_TX_IDLE;
  end else begin
    tx_stat <= tx_stat_next;
  end
end

always_ff @ (posedge uart_clk8) begin
  if (rst) begin
    tx_stat_last <= UART_TX_IDLE;
  end else begin
    tx_stat_last <= tx_stat;
  end
end

endmodule
