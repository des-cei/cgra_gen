// Copyright 2024 CEI-UPM
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
// Daniel Vazquez (daniel.vazquez@upm.es)

#include <stdint.h>


struct Kernel {
	int n_pe;
	int size;
	int bytes;
	int n_inputs;
	int n_outputs;
	int *inputs;
	int *outputs;
	uint32_t *kernel;
};

// Bypass kernel 4x4 CGRA
#define BYPASS_4X4_NPE 16
#define BYPASS_4X4_NIN 4
#define BYPASS_4X4_NOUT 4
#define BYPASS_4X4_SIZE BYPASS_4X4_NPE * 4
#define BYPASS_4X4_BYTES BYPASS_4X4_SIZE * 4

int bypass_inputs_4x4[BYPASS_4X4_NIN] = {1, 1, 1, 1}; // All inputs active
int bypass_outputs_4x4[BYPASS_4X4_NOUT] = {1, 1, 1, 1}; // All outputs active

uint32_t bypass_kernel_4x4[BYPASS_4X4_SIZE] = {
	0x10000002, 0x00000000, 0x00000000, 0x00010000, //  0
	0x10000002, 0x00000000, 0x00000000, 0x00010001, //  1
	0x10000002, 0x00000000, 0x00000000, 0x00010002, //  2
	0x10000002, 0x00000000, 0x00000000, 0x00010003, //  3

	0x10000002, 0x00000000, 0x00000000, 0x00010004, //  4
	0x10000002, 0x00000000, 0x00000000, 0x00010005, //  5
	0x10000002, 0x00000000, 0x00000000, 0x00010006, //  6
	0x10000002, 0x00000000, 0x00000000, 0x00010007, //  7

	0x10000002, 0x00000000, 0x00000000, 0x00010008, //  8
	0x10000002, 0x00000000, 0x00000000, 0x00010009, //  9
	0x10000002, 0x00000000, 0x00000000, 0x0001000A, // 10
	0x10000002, 0x00000000, 0x00000000, 0x0001000B, // 11

	0x10000002, 0x00000000, 0x00000000, 0x0001000C, // 12
	0x10000002, 0x00000000, 0x00000000, 0x0001000D, // 13
	0x10000002, 0x00000000, 0x00000000, 0x0001000E, // 14
	0x10000002, 0x00000000, 0x00000000, 0x0001000F  // 15
};

Kernel bypass_4x4 = { 
	.n_pe = BYPASS_4X4_NPE,
	.size = BYPASS_4X4_SIZE,
	.bytes = BYPASS_4X4_BYTES,
	.n_inputs = BYPASS_4X4_NIN,
	.n_outputs = BYPASS_4X4_NOUT,
	.inputs = bypass_inputs_4x4,
	.outputs = bypass_outputs_4x4,
	.kernel = bypass_kernel_4x4
};
