_start:
  addi x1, x0, 0
  la x2, _test_data
  la x4, 0xe0000000
_loop:
  lb x3, 0(x2)
  beq x3, x0, _exit
  sb x3, 0(x4)
  addi x2, x2, 1
  j _loop

_exit:
  j _exit

.section .data
_test_data:
  .string "Hello World!"
