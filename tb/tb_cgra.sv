// Copyright 2025 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module tb_cgra;

    // Local parameters for the simulation
    localparam int DATA_WIDTH = 32;

    logic clk, rst_n;
    logic [4*DATA_WIDTH-1:0] data_in, data_out;
    logic [3:0] data_in_valid, data_in_ready, data_out_valid, data_out_ready;
    logic [127:0] config_bitstream;

    // Instantiate UUT
    cgra #(
        .DATA_WIDTH(DATA_WIDTH)
    ) cgra_i (
        .clk(clk),
        .clk_bs(clk),
        .rst_n(rst_n),
        .rst_bs(!rst_n),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_in_ready(data_in_ready),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .data_out_ready(data_out_ready),
        .config_bitstream(config_bitstream)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #0.5 clk = ~clk;
    end

    // Stimuli generation
    initial begin
        // Assert reset signal
        rst_n = 1'b0;

        // Reset state
        data_in = '0;
        data_in_valid = '0;
        data_out_ready = '0;
        config_bitstream = '0;

        #10 $display("Simulation START");

        // Core evaluation
        rst_n = 1'b1;

        // End simulation
        #100 $display("Simulation FINISH");
        $finish;
    end

endmodule
