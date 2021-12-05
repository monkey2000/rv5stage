_start:
  la x1, _test_data
  lw x2, 0(x1)
  addi x2, x2, 1
  sw x2, 0(x1)
  lw x3, 0(x1)

.section .data
_test_data:
  .word 0x00000000
