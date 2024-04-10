# Copyright 2024 CEI-UPM
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Daniel Vazquez (daniel.vazquez@upm.es)

base_dir=$(abspath ..)
rtl_dir=$(abspath ../rtl)

PROJECT ?= CGRA

TOP_MODULE = $(rtl_dir)/generated/CGRA
MODULES = $(rtl_dir)/*.sv

.PHONY:sim
sim: waveform.vcd

.PHONY:verilate
verilate: .stamp.verilate

.PHONY:build
build: obj_dir/V$(TOP_MODULE)

.PHONY:waves
waves: waveform.vcd
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd -a ./signals_4x4.gtkw

waveform.vcd: ./obj_dir/V$(TOP_MODULE)
	@echo
	@echo "### SIMULATING ###"
	@./obj_dir/V$(PROJECT)

./obj_dir/V$(TOP_MODULE): .stamp.verilate
	@echo
	@echo "### BUILDING SIM ###"
	make -C obj_dir -f V$(PROJECT).mk V$(PROJECT)

.stamp.verilate: $(TOP_MODULE).sv $(PROJECT)_tb.cpp
	@echo
	@echo "### VERILATING ###"
	verilator -Wall --trace -Wno-PINCONNECTEMPTY -Wno-GENUNNAMED -Wno-UNUSED -cc $(TOP_MODULE).sv $(MODULES) --exe $(PROJECT)_tb.cpp
	@touch .stamp.verilate

.PHONY:lint
lint: $(TOP_MODULE).sv
	verilator --lint-only $(TOP_MODULE).sv

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
