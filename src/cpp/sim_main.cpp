#include "Vtop.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
uint64_t global_ticks = 0;

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

    tfp->close();
    delete tfp;
    delete top;
    exit(0);
}
