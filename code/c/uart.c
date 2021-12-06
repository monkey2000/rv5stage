#define ENTRY __attribute__((__section__(".entrypoint")))

volatile char *uart_mmio = (volatile char *) 0xe0000000;

void uart_write(char c) {
  (*uart_mmio) = c;
}

void uart_print(char *p) {
  for (; *p; p++) {
    uart_write(*p);
  }
}

void ENTRY _start() {
  uart_print("Hello World!");
  while (1);
}
