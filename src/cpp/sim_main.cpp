#include <iostream>
#include "Vtop.h"
// #include "verilated.h"
// #include "Vtop___024root.h"
#include <verilated_vcd_c.h>
uint64_t global_ticks = 0;

// uint32_t inspect_value(Vtop *top, int pos) {
//     assert(pos >= 0 && pos < 32);
//     return top->rootp->top__DOT__regfile__DOT__regs[pos];
// }

int main(int argc, char **argv, char **env) {
    Verilated::commandArgs(argc, argv);
    Vtop *top = new Vtop;

    VerilatedVcdC* tfp = NULL;
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    Verilated::mkdir("logs");
    tfp->open("logs/vlt_dump.vcd");

    while (!Verilated::gotFinish() && global_ticks < 1000) {
        global_ticks++;
        if (global_ticks % 10 == 0) {
            top->clk = 1;
        } else if (global_ticks % 10 == 5) {
            top->clk = 0;
        }

        if (global_ticks < 19) {
            top->rst = 1;
        } else {
            top->rst = 0;
        }

        top->eval();
        tfp->dump(global_ticks);
    }

    std::cout << "Simulation Finished" << std::endl;

    // for (int i = 0; i < 32; i++) {
    //     std::cout << "Reg[" << std::dec << i << "] = " << std::hex << inspect_value(top, i) << std::endl;
    // }

    tfp->close();
    delete tfp;
    delete top;
    exit(0);
}
