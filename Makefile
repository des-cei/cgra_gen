# Copyright 2024 CEI-UPM
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
# Daniel Vazquez (daniel.vazquez@upm.es)

FUSESOC := $(shell which fusesoc)
PYTHON  := $(shell which python)

RTL_FILES := $(wildcard rtl/*.sv)

verible:
	@for file in $(RTL_FILES); do \
		verible-verilog-format $$file --inplace \
			--formal_parameters_indentation indent --named_parameter_indentation indent \
			--named_port_indentation indent --port_declarations_indentation indent 2> /dev/null; \
		verible-verilog-lint $$file --lint_fatal=false --parse_fatal=false; \
	done

cgra-gen:
	$(PYTHON) generator/CGRA_generator.py
	$(MAKE) verible

questasim-sim: cgra-gen
	$(FUSESOC) --cores-root . run --no-export --target=sim --tool=modelsim $(FUSESOC_FLAGS) --build ceiupm:systems:elastic-cgra ${FUSESOC_PARAM} 2>&1 | tee buildsim.log
	$(MAKE) -C build/ceiupm_systems_elastic-cgra_0/sim-modelsim/ opt

run-app-questasim:
	$(MAKE) -C build/ceiupm_systems_elastic-cgra_0/sim-modelsim/ run RUN_OPT=1

run-app-gui-questasim:
	$(MAKE) -C build/ceiupm_systems_elastic-cgra_0/sim-modelsim/ run-gui RUN_OPT=1

.PHONY: bitstream
bitstream:
	$(PYTHON) bitstream/PE_bsgen.py

clean:
	rm -rf build/
	rm -f rtl/cgra.sv
