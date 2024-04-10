// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module processing_element
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Clock and reset
        input  logic                    clk,
        input  logic                    clk_bs,
        input  logic                    rst_n,
        input  logic                    rst_bs,

        // Input data
        input  logic [DATA_WIDTH-1:0]   north_din,
        input  logic                    north_din_v,
        output logic                    north_din_r,
        input  logic [DATA_WIDTH-1:0]   east_din,
        input  logic                    east_din_v,
        output logic                    east_din_r,
        input  logic [DATA_WIDTH-1:0]   south_din,
        input  logic                    south_din_v,
        output logic                    south_din_r,
        input  logic [DATA_WIDTH-1:0]   west_din,
        input  logic                    west_din_v,
        output logic                    west_din_r,

        // Output data
        output logic [DATA_WIDTH-1:0]   north_dout,
        output logic                    north_dout_v,
        input  logic                    north_dout_r,
        output logic [DATA_WIDTH-1:0]   east_dout,
        output logic                    east_dout_v,
        input  logic                    east_dout_r,
        output logic [DATA_WIDTH-1:0]   south_dout,
        output logic                    south_dout_v,
        input  logic                    south_dout_r,
        output logic [DATA_WIDTH-1:0]   west_dout,
        output logic                    west_dout_v,
        input  logic                    west_dout_r,

        // Configuration
        input  logic [95:0]             config_bits,
        input  logic                    catch_config
    );

    // Config signals
    logic [1:0]             mux_sel_n, mux_sel_e, mux_sel_s, mux_sel_w;
    logic [4:0]             mask_fs_n, mask_fs_e, mask_fs_s, mask_fs_w;
    logic [95:0]            config_reg;

    // Interconnect signals
    // Buffer
    logic [DATA_WIDTH-1:0]  north_buffer, east_buffer, south_buffer, west_buffer;
    logic                   north_buffer_v, east_buffer_v, south_buffer_v, west_buffer_v;
    logic                   temp_north_buffer_v, temp_east_buffer_v, temp_south_buffer_v, temp_west_buffer_v;
    logic                   north_buffer_r, east_buffer_r, south_buffer_r, west_buffer_r;
    // Processing cell
    logic                   din_1_r, din_2_r;
    logic [DATA_WIDTH-1:0]  dout;
    logic                   dout_v;

    // Configuration register
    always_ff @(posedge clk_bs or posedge rst_bs) begin
        if(rst_bs) begin
            config_reg <= 0;
        end else if(catch_config) begin
            config_reg <= config_bits;
        end
    end

    // Configuration decoding
    assign mask_fs_n = config_reg[4:0];
    assign mask_fs_e = config_reg[10:6];
    assign mask_fs_s = config_reg[16:12];
    assign mask_fs_w = config_reg[22:18];
    assign mux_sel_n = config_reg[25:24];
    assign mux_sel_e = config_reg[27:26];
    assign mux_sel_s = config_reg[29:28];
    assign mux_sel_w = config_reg[31:30];

    /* ------------------------------ NORTH NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_N
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .din        ( north_din             ),
        .din_v      ( north_din_v           ),
        .din_r      ( north_din_r           ),
        .dout       ( north_buffer          ),
        .dout_v     ( temp_north_buffer_v   ),
        .dout_r     ( north_buffer_r        )
    );

    assign north_buffer_v   = temp_north_buffer_v && north_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   5                                                           )
    )
    FS_N
    (
        .ready_in   (   north_buffer_r                                              ),
        .ready_out  ( { din_1_r, din_2_r, east_dout_r, south_dout_r, west_dout_r }  ),
        .fork_mask  (   mask_fs_n                                                   )
    );

    // Output
    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_N
    (
        .sel        (   mux_sel_n                                       ),
        .mux_in     ( { west_buffer, south_buffer, east_buffer, dout }  ),
        .mux_out    (   north_dout                                      )
    );

    mux
    #(
        .NUM_INPUTS (   4                                                       ),
        .DATA_WIDTH (   1                                                       )
    )
    MUX_N_v
    (
        .sel        (   mux_sel_n                                               ),
        .mux_in     ( { west_buffer_v, south_buffer_v, east_buffer_v, dout_v }  ),
        .mux_out    (   north_dout_v                                            )
    );

    /* ------------------------------ NORTH NODE ------------------------------- */

    /* ------------------------------ EAST  NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_E
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .din        ( east_din              ),
        .din_v      ( east_din_v            ),
        .din_r      ( east_din_r            ),
        .dout       ( east_buffer           ),
        .dout_v     ( temp_east_buffer_v    ),
        .dout_r     ( east_buffer_r         )
    );

    assign east_buffer_v    = temp_east_buffer_v && east_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   5                                                           )
    )
    FS_E
    (
        .ready_in   (   east_buffer_r                                               ),
        .ready_out  ( { din_1_r, din_2_r, north_dout_r, south_dout_r, west_dout_r } ),
        .fork_mask  (   mask_fs_e                                                   )
    );

    // Output
    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_E
    (
        .sel        (   mux_sel_e                                       ),
        .mux_in     ( { west_buffer, south_buffer, north_buffer, dout } ),
        .mux_out    (   east_dout                                       )
    );

    mux
    #(
        .NUM_INPUTS (   4                                                       ),
        .DATA_WIDTH (   1                                                       )
    )
    MUX_E_v
    (
        .sel        (   mux_sel_e                                               ),
        .mux_in     ( { west_buffer_v, south_buffer_v, north_buffer_v, dout_v } ),
        .mux_out    (   east_dout_v                                             )
    );

    /* ------------------------------ EAST  NODE ------------------------------- */

    /* ------------------------------ SOUTH NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH            )
    )
    REG_S
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .din        ( south_din             ),
        .din_v      ( south_din_v           ),
        .din_r      ( south_din_r           ),
        .dout       ( south_buffer          ),
        .dout_v     ( temp_south_buffer_v   ),
        .dout_r     ( south_buffer_r        )
    );

    assign south_buffer_v   = temp_south_buffer_v && south_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   5                                                           )
    )
    FS_S
    (
        .ready_in   (   south_buffer_r                                              ),
        .ready_out  ( { din_1_r, din_2_r, north_dout_r, east_dout_r, west_dout_r }  ),
        .fork_mask  (   mask_fs_s                                                   )
    );

    // Output
    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_S
    (
        .sel        (   mux_sel_s                                       ),
        .mux_in     ( { west_buffer, east_buffer, north_buffer, dout }  ),
        .mux_out    (   south_dout                                      )
    );

    mux
    #(
        .NUM_INPUTS (   4                                                       ),
        .DATA_WIDTH (   1                                                       )
    )
    MUX_S_v
    (
        .sel        (   mux_sel_s                                               ),
        .mux_in     ( { west_buffer_v, east_buffer_v, north_buffer_v, dout_v }  ),
        .mux_out    (   south_dout_v                                            )
    );

    /* ------------------------------ SOUTH NODE ------------------------------- */

    /* ------------------------------ WEST  NODE ------------------------------- */

    // Input
    elastic_buffer
    #(
        .DATA_WIDTH ( DATA_WIDTH    )
    )
    REG_W
    (
        .clk        ( clk                   ),
        .rst_n      ( rst_n                 ),
        .din        ( west_din              ),
        .din_v      ( west_din_v            ),
        .din_r      ( west_din_r            ),
        .dout       ( west_buffer           ),
        .dout_v     ( temp_west_buffer_v    ),
        .dout_r     ( west_buffer_r         )
    );

    assign west_buffer_v    = temp_west_buffer_v && west_buffer_r;

    fork_sender
    #(
        .NUM_READYS (   5                                                                       )
    )
    FS_W
    (
        .ready_in   (   west_buffer_r                                               ),
        .ready_out  ( { din_1_r, din_2_r, north_dout_r, east_dout_r, south_dout_r } ),
        .fork_mask  (   mask_fs_w                                                   )
    );

    // Output
    mux
    #(
        .NUM_INPUTS (   4                                               ),
        .DATA_WIDTH (   DATA_WIDTH                                      )
    )
    MUX_W
    (
        .sel        (   mux_sel_w                                       ),
        .mux_in     ( { south_buffer, east_buffer, north_buffer, dout } ),
        .mux_out    (   west_dout                                       )
    );

    mux
    #(
        .NUM_INPUTS (   4                                                       ),
        .DATA_WIDTH (   1                                                       )
    )
    MUX_W_v
    (
        .sel        (   mux_sel_w                                               ),
        .mux_in     ( { south_buffer_v, east_buffer_v, north_buffer_v, dout_v } ),
        .mux_out    (   west_dout_v                                             )
    );

    /* ------------------------------ WEST  NODE ------------------------------- */

    processing_cell
    #(
        .DATA_WIDTH     ( DATA_WIDTH        )
    )
    PC
    (
        .clk            ( clk               ),
        .rst_n          ( rst_n             ),
        .north_din      ( north_buffer      ),
        .north_din_v    ( north_buffer_v    ),
        .east_din       ( east_buffer       ),
        .east_din_v     ( east_buffer_v     ),
        .south_din      ( south_buffer      ),
        .south_din_v    ( south_buffer_v    ),
        .west_din       ( west_buffer       ),
        .west_din_v     ( west_buffer_v     ),
        .din_1_r        ( din_1_r           ),
        .din_2_r        ( din_2_r           ),
        .dout           ( dout              ),
        .dout_v         ( dout_v            ),
        .north_dout_r   ( north_dout_r      ),
        .east_dout_r    ( east_dout_r       ),
        .south_dout_r   ( south_dout_r      ),
        .west_dout_r    ( west_dout_r       ),
        .config_bits    ( config_reg[95:32] )
    );

endmodule
