#include "Vtop.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
uint64_t global_ticks = 0;

int main(int argc, char **argv, char **env){
    Verilated::commandArgs(argc, argv);
    Vtop *top = new Vtop;

    VerilatedVcdC* tfp = NULL;
    Verilated::traceEverOn(true);
    VL_PRINTF("Enabling waves into logs/vlt_dump.vcd...\n");
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    Verilated::mkdir("logs");
    tfp->open("logs/vlt_dump.vcd");

    while (!Verilated::gotFinish() && global_ticks < 1000) {
        global_ticks++;
        if (global_ticks % 10 == 1) {
            top->clk = 1;
        } else if (global_ticks % 10 == 6) {
            top->clk = 0;
        }
        top->a = global_ticks & 1;
        top->b = (global_ticks & 1) ^ 1;
        top->eval();
        tfp->dump(global_ticks);
    }

    tfp->close();
    delete tfp;
    delete top;
    exit(0);
}
