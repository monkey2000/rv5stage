#include <iostream>
#include "Vtop.h"
#include "verilated.h"
#include "Vtop___024root.h"
#include "clock_gen.hpp"
#include "uart_cosim.hpp"
#include <verilated_vcd_c.h>
uint64_t global_ticks = 0;

uint32_t inspect_value(Vtop *top, int pos) {
    assert(pos >= 0 && pos < 32);
    return top->rootp->top__DOT__regfile__DOT__regs[pos];
}

void print_regfile(Vtop *top) {
    std::cout << "========== " << std::dec << global_ticks << " ==========" << std::endl;
    for (int i = 0; i < 32; i++) {
        std::cout << "Reg[" << std::dec << i << "] = " << std::hex << inspect_value(top, i) << std::endl;
    }
}

int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);
    Vtop *top = new Vtop;

    VerilatedVcdC* tfp = NULL;
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    Verilated::mkdir("logs");
    tfp->open("logs/vlt_dump.vcd");

    clock_gen system_clk(10000 / 2);  // 10000ps 10MHz
    clock_gen uart_clk8(1085069 / 2); // 1085069ps 921600Hz
    clock_gen uart_clk(8680555 / 2);  // 8680555ps 115200bps

    uart_cosim uart("logs/uart.txt");

    top->clk = 0;
    top->uart_clk8 = 0;
    top->uart_clk = 0;
    top->rst = 1;

    while (!Verilated::gotFinish() && global_ticks < 10000 * 1000000ULL) {
        top->eval();
        tfp->dump(global_ticks);
        tfp->flush();
        if (global_ticks > 50)
            top->rst = 0;
        
        if (uart_clk8.rising_edge()) {
            uart.update(top->uart_tx);
        }

        uint64_t min_to_next_tick = system_clk.time_to_edge();

        if (uart_clk8.time_to_edge() < min_to_next_tick)
            min_to_next_tick = uart_clk8.time_to_edge();

        if (uart_clk.time_to_edge() < min_to_next_tick)
            min_to_next_tick = uart_clk.time_to_edge();

        top->clk = system_clk.advance(min_to_next_tick);
        top->uart_clk8 = uart_clk8.advance(min_to_next_tick);
        top->uart_clk = uart_clk.advance(min_to_next_tick);
        global_ticks += min_to_next_tick;
    }

    std::cout << "Simulation Finished" << std::endl;

    print_regfile(top);

    tfp->close();
    delete tfp;
    delete top;
    exit(0);
}
