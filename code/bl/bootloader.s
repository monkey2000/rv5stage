.extern main

.section .bootloader
.global _start
_start:
  la sp, _stack_top
  jal main
  j _start


.section .data
.global _stack
.global _stack_top
.align 12
_stack:
  .fill 0x1000, 0x00
_stack_top:
  .word 0x00000000
