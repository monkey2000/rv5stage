ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

default:
	@echo "-- Verilator hello-world simple example"
	@echo "-- VERILATE ----------------"
	$(VERILATOR) --trace -cc --exe src/rtl/top.sv src/cpp/sim_main.cpp
	@echo "-- COMPILE -----------------"
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk
	@echo "-- RUN ---------------------"
	obj_dir/Vtop
	@echo "-- DONE --------------------"
	@echo "Note: Once this example is understood, see examples/tracing_c."
	@echo "Note: Also see the EXAMPLE section in the verilator manpage/document."
