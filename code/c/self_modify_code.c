#include <stdint.h>

volatile char *uart_mmio = (volatile char *) 0xe0000000;

void uart_write(char c) {
  (*uart_mmio) = c;
}

void uart_print(char *p) {
  for (; *p; p++) {
    uart_write(*p);
  }
}

void print_hex(uint32_t x) {
  for (int i = 7; i >= 0; i--) {
    uint32_t h = (x >> (i * 4)) & 0xf;
    if (h < 10)
      uart_write(h + '0');
    else
      uart_write(h - 10 + 'a');
  }
}

uint32_t fib(uint32_t x) {
  if (x < 2)
    return x;
  else
    return fib(x - 1) + fib(x - 2);
}

void main() {
  uint32_t x0 = fib(10);

  void *fib_addr = fib;
  uint32_t *p = (uint32_t *) fib_addr;
  p[0] = 0x00008067; // ret hijack

  for (int i = 0; i < 20; i++)
    asm volatile ("nop");

  uint32_t x = fib(10);
  print_hex(x0);
  uart_print("\n");
  print_hex(x);

  while (1);
}
