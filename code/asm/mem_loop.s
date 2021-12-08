_start:
  li x0, 0
  li x1, 0
  li x2, 10
  la x3, _test_data
loop:
  addi x1, x1, 1
  li x4, 0
  lw x4, 0(x3)
  addi x4, x4, 1
  sw x4, 0(x3)
  blt x1, x2, loop
end:
  j end

.section .data
_test_data:
  .word 0x00000000
