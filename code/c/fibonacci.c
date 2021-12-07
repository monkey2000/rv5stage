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

uint32_t fib(uint32_t x) {
  if (x < 2)
    return x;
  else
    return fib(x - 1) + fib(x - 2);
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

void main() {
  uint32_t x = fib(3);
  print_hex(x);
  while (1);
}
