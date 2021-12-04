_start:
  addi x1, x0, 0
  addi x2, x0, 0
loop:
  addi x1, x1, 1
  addi x2, x2, 2
  j loop
