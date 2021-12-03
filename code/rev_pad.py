#!/usr/bin/env python3
import sys

def main():
  for line in sys.stdin:
    line = str(line.strip())
    line = line.ljust(32, '0')
    l = len(line)
    line = ''.join([line[i]+line[i+1] for i in range(l - 2, -1, -2)])
    line = '_'.join([line[i*8:i*8+8] for i in range(4)])
    print(line)


if __name__ == '__main__':
  main()
