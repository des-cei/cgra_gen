// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module processing_cell
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Clock and reset
        input  logic                    clk,
        input  logic                    rst_n,

        // Input data
        input  logic [DATA_WIDTH-1:0]   north_din,
        input  logic                    north_din_v,
        input  logic [DATA_WIDTH-1:0]   east_din,
        input  logic                    east_din_v,
        input  logic [DATA_WIDTH-1:0]   south_din,
        input  logic                    south_din_v,
        input  logic [DATA_WIDTH-1:0]   west_din,
        input  logic                    west_din_v,
        output logic                    din_1_r,
        output logic                    din_2_r,

        // Output data
        output logic [DATA_WIDTH-1:0]   dout,
        output logic                    dout_v,
        input  logic                    north_dout_r,
        input  logic                    east_dout_r,
        input  logic                    south_dout_r,
        input  logic                    west_dout_r,

        // Configuration
        input  logic [63:0]             config_bits
    );

    // Config signals
    logic [2:0]             mux_sel_1, mux_sel_2;
    logic [3:0]             mask_fs;
    logic [DATA_WIDTH-1:0]  I1_const;
    logic [15:0]            iterations_reset;
    logic                   feedback;
    logic [3:0]             op_config;

    // Interconnect signals
    logic [DATA_WIDTH-1:0] EB_din_1, EB_din_2, join_din_1, join_din_2, join_dout_1, join_dout_2;
    logic EB_din_1_v, EB_din_2_v;
    logic join_din_1_v, join_din_1_r, join_din_2_v, join_din_2_r, join_dout_v, join_dout_r;
    logic temp_dout_v, forked_dout_r;

    // Configuration decoding
    assign mux_sel_1        = config_bits[2:0];
    assign mux_sel_2        = config_bits[5:3];
    assign mask_fs          = config_bits[9:6];
    assign iterations_reset = config_bits[25:10];
    assign feedback         = config_bits[26:26];
    assign op_config        = config_bits[30:27];
    assign I1_const         = $unsigned(DATA_WIDTH'(signed'(config_bits[63:32])));

    // Data path in 1
    mux
    #(
        .NUM_INPUTS (   5                                                       ),
        .DATA_WIDTH (   DATA_WIDTH                                              )
    )
    MUX_1
    (
        .sel        (   mux_sel_1                                               ),
        .mux_in     ( { I1_const, west_din, south_din, east_din, north_din }    ),
        .mux_out    (   EB_din_1                                                )
    );

    mux
    #(
        .NUM_INPUTS (   5                                                           ),
        .DATA_WIDTH (   1                                                           )
    )
    MUX_1_v
    (
        .sel        (   mux_sel_1                                                   ),
        .mux_in     ( { 1'b1, west_din_v, south_din_v, east_din_v, north_din_v }    ),
        .mux_out    (   EB_din_1_v                                                  )
    );

    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH    )
    )
    REG_1
    (
        .clk        ( clk           ),
        .rst_n      ( rst_n         ),
        .din        ( EB_din_1      ),
        .din_v      ( EB_din_1_v    ),
        .din_r      ( din_1_r       ),
        .dout       ( join_din_1    ),
        .dout_v     ( join_din_1_v  ),
        .dout_r     ( join_din_1_r  )
    );

    // Data path in 2
    mux
    #(
        .NUM_INPUTS (   5                                                       ),
        .DATA_WIDTH (   DATA_WIDTH                                              )
    )
    MUX_2
    (
        .sel        (   mux_sel_2                                               ),
        .mux_in     ( { I1_const, west_din, south_din, east_din, north_din }    ),
        .mux_out    (   EB_din_2                                                )
    );

    mux
    #(
        .NUM_INPUTS (   5                                                           ),
        .DATA_WIDTH (   1                                                           )
    )
    MUX_2_v
    (
        .sel        (   mux_sel_2                                                   ),
        .mux_in     ( { 1'b1, west_din_v, south_din_v, east_din_v, north_din_v }    ),
        .mux_out    (   EB_din_2_v                                                  )
    );

    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH )
    )
    REG_2
    (
        .clk        ( clk           ),
        .rst_n      ( rst_n         ),
        .din        ( EB_din_2      ),
        .din_v      ( EB_din_2_v    ),
        .din_r      ( din_2_r       ),
        .dout       ( join_din_2    ),
        .dout_v     ( join_din_2_v  ),
        .dout_r     ( join_din_2_r  )
    );

    // Data path out    
    elastic_join
    #(
        .DATA_WIDTH     ( DATA_WIDTH )
    )
    join_inst
    (
        .din_1          ( join_din_1    ),
        .din_1_v        ( join_din_1_v  ),
        .din_1_r        ( join_din_1_r  ),
        .din_2          ( join_din_2    ),
        .din_2_v        ( join_din_2_v  ),
        .din_2_r        ( join_din_2_r  ),
        .dout_1         ( join_dout_1   ),
        .dout_2         ( join_dout_2   ),
        .dout_v         ( join_dout_v   ),
        .dout_r         ( join_dout_r   ),
        .feedback       ( feedback      )
    );

    functional_unit
    #(
        .DATA_WIDTH         ( DATA_WIDTH        )
    )
    FU
    (
        .clk                ( clk               ),
        .rst_n              ( rst_n             ),
        .din_1              ( join_dout_1       ),
        .din_2              ( join_dout_2       ),
        .din_v              ( join_dout_v       ),
        .din_r              ( join_dout_r       ),
        .dout               ( dout              ),
        .dout_v             ( temp_dout_v       ),
        .dout_r             ( forked_dout_r     ),
        .feedback           ( feedback          ),
        .initial_value      ( I1_const          ),
        .delay_value        ( iterations_reset  ),
        .alu_sel            ( op_config         )
    );

    assign dout_v = temp_dout_v & forked_dout_r;

    fork_sender
    #(
        .NUM_READYS (   4                                                       )
    )
    FS
    (
        .ready_in   (   forked_dout_r                                           ),
        .ready_out  ( { north_dout_r, east_dout_r, south_dout_r, west_dout_r }  ),
        .fork_mask  (   mask_fs                                                 )
    );

endmodule
