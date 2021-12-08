#include <iostream>
#include <fstream>

class uart_cosim {
private:
  std::fstream file;
  int counter_supersample;
  int counter_protocol;
  char recv;

public:
  uart_cosim(std::string filename) {
    file.open(filename, std::ios::out | std::ios::trunc);
    counter_supersample = 0;
    counter_protocol = -2;
  }

  ~uart_cosim() {
    file.close();
  }

  void update(int uart_tx) {
    printf("%d %d %c\n", counter_protocol, uart_tx, recv);
    if (counter_protocol == -2 && uart_tx == 0) {
      counter_protocol++;
      recv = 0;
    } else if (counter_protocol != -2) {
      counter_protocol = counter_protocol + (counter_supersample == 7);
      counter_supersample = (counter_supersample + 1) % 8;
    }

    if (counter_protocol == 8 && counter_supersample == 4) {
      file << recv << std::flush;
      counter_supersample = 0;
      counter_protocol = -2;
    }

    if (counter_protocol >= 0 && counter_protocol < 8 && counter_supersample == 4) {
      recv = recv | (uart_tx << counter_protocol);
    }
  }
};
