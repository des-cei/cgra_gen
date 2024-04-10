# Copyright 2024 CEI-UPM
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
# Daniel Vazquez (daniel.vazquez@upm.es)

default: generate

# Generate the CGRA
.PHONY: generate
generate:
	if [ ! -d "rtl/generated" ]; then mkdir rtl/generated; fi
	python3.10 generator/CGRA_generator.py

.PHONY: clean_gen
clean_gen:
	if [ -d "rtl/generated" ]; then rm -R rtl/generated; fi

# Simulate the CGRA
.PHONY: simulate
simulate:
	+$(MAKE) -C tb/ sim

.PHONY: waves
waves:
	+$(MAKE) -C tb/ waves

.PHONY: clean_sim
clean_sim:
	+$(MAKE) -C tb/ clean

# Print bitstream
.PHONY: bitstream
bitstream:
	python3.10 bitstream/PE_bsgen.py

# Clean
.PHONY: clean
clean: clean_gen clean_sim	
	
# Help
HELP_COMMANDS = \
"   help        = display this help" \
" [ generate ]  = generates a CGRA as specified in the configuration file" \
"   simulate    = compiles debug simulator and opens the waveform" \
"   bitstream   = prints the bitstream of a PE type using the configuration file" \
"   clean       = removes all" \
"   clean-gen   = removes the CGRA generated file" \
"   clean-sim   = removes simulator and simulator-generated files" \
""
HELP_LINES = "" \
	" General commands:" \
	" -----------------------------" \
	$(HELP_COMMANDS) \
	""

.PHONY: help
help:
	@for line in $(HELP_LINES); do echo "$$line"; done
