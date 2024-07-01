// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module processing_element
    #(
        parameter int DATA_WIDTH = 32,
        parameter string CONFIG_BORDER = "north"
    )
    (
        // Clock and reset
        input  logic                    clk,
        input  logic                    rst_n,
        input  logic                    clr_data,
        input  logic                    clr_config,

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
        input  logic                    config_en_i,
        output logic                    config_en_o
    );

    // Config signals
    logic [1:0]                         mux_sel_n, mux_sel_e, mux_sel_s, mux_sel_w;
    logic [4:0]                         mask_fs_n, mask_fs_e, mask_fs_s, mask_fs_w;
    logic [95:0]                        config_wire, config_reg;
    logic                               tmp_north_din_v, tmp_east_din_v, tmp_south_din_v, tmp_west_din_v;
    logic [DATA_WIDTH-1:0]              tmp_north_dout, tmp_east_dout, tmp_south_dout, tmp_west_dout;
    logic [$clog2(96/DATA_WIDTH)-1:0]   config_cnt;

    // Interconnect signals
    // Buffer
    logic [DATA_WIDTH-1:0]  north_buffer, east_buffer, south_buffer, west_buffer;
    logic                   north_buffer_v, east_buffer_v, south_buffer_v, west_buffer_v;
    logic                   tmp_north_buffer_v, tmp_east_buffer_v, tmp_south_buffer_v, tmp_west_buffer_v;
    logic                   north_buffer_r, east_buffer_r, south_buffer_r, west_buffer_r;
    // Processing cell
    logic                   din_1_r, din_2_r;
    logic [DATA_WIDTH-1:0]  dout;
    logic                   dout_v;

    // Configuration signals
    generate
        if (CONFIG_BORDER == "north") begin
            assign config_wire = {north_din, config_reg[95:DATA_WIDTH]};
            assign tmp_north_din_v = north_din_v && !config_en_i;
            assign tmp_east_din_v  = east_din_v;
            assign tmp_south_din_v = south_din_v;
            assign tmp_west_din_v  = west_din_v;
            assign north_dout = tmp_north_dout;
            assign east_dout  = tmp_east_dout;
            assign south_dout = config_en_i ? config_reg[DATA_WIDTH-1:0] : tmp_south_dout;
            assign west_dout  = tmp_west_dout;
        end else if (CONFIG_BORDER == "east") begin
            assign config_wire = { east_din, config_reg[95:DATA_WIDTH]};
            assign tmp_north_din_v = north_din_v;
            assign tmp_east_din_v  = east_din_v && !config_en_i;
            assign tmp_south_din_v = south_din_v;
            assign tmp_west_din_v  = west_din_v;
            assign north_dout = tmp_north_dout;
            assign east_dout  = tmp_east_dout;
            assign south_dout = tmp_south_dout;
            assign west_dout  = config_en_i ? config_reg[DATA_WIDTH-1:0] : tmp_west_dout;
        end else if (CONFIG_BORDER == "south") begin
            assign config_wire = {south_din, config_reg[95:DATA_WIDTH]};
            assign tmp_north_din_v = north_din_v;
            assign tmp_east_din_v  = east_din_v;
            assign tmp_south_din_v = south_din_v && !config_en_i;
            assign tmp_west_din_v  = west_din_v;
            assign north_dout = config_en_i ? config_reg[DATA_WIDTH-1:0] : tmp_north_dout;
            assign east_dout  = tmp_east_dout;
            assign south_dout = tmp_south_dout;
            assign west_dout  = tmp_west_dout;
        end else if (CONFIG_BORDER == "west") begin
            assign config_wire = { west_din, config_reg[95:DATA_WIDTH]};
            assign tmp_north_din_v = north_din_v;
            assign tmp_east_din_v  = east_din_v;
            assign tmp_south_din_v = south_din_v;
            assign tmp_west_din_v  = west_din_v && !config_en_i;
            assign north_dout = tmp_north_dout;
            assign east_dout  = config_en_i ? config_reg[DATA_WIDTH-1:0] : tmp_east_dout;
            assign south_dout = tmp_south_dout;
            assign west_dout  = tmp_west_dout;
        end else begin // north default
            assign config_wire = {north_din, config_reg[95:DATA_WIDTH]};
            assign tmp_north_din_v = north_din_v && !config_en_i;
            assign tmp_east_din_v  = east_din_v;
            assign tmp_south_din_v = south_din_v;
            assign tmp_west_din_v  = west_din_v;
            assign north_dout = tmp_north_dout;
            assign east_dout  = tmp_east_dout;
            assign south_dout = config_en_i ? config_reg[DATA_WIDTH-1:0] : tmp_south_dout;
            assign west_dout  = tmp_west_dout;
        end
    endgenerate

    // Configuration registers
    // synopsys sync_set_reset clr_config
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            config_reg <= 0;
            config_cnt <= 0;
        end else begin
            if (clr_config) begin
                config_reg <= 0;
                config_cnt <= 0;               
            end else if (config_en_i) begin
                config_reg <= config_wire;
                if (config_cnt < 96/DATA_WIDTH) begin
                    config_cnt <= config_cnt + 1;
                end
            end
        end
    end

    assign config_en_o = config_en_i && config_cnt == 96/DATA_WIDTH;

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
        .clr        ( clr_data              ),
        .din        ( north_din             ),
        .din_v      ( tmp_north_din_v      ),
        .din_r      ( north_din_r           ),
        .dout       ( north_buffer          ),
        .dout_v     ( tmp_north_buffer_v   ),
        .dout_r     ( north_buffer_r        )
    );

    assign north_buffer_v   = tmp_north_buffer_v && north_buffer_r;

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
        .mux_out    (   tmp_north_dout                                  )
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
        .clr        ( clr_data              ),
        .din        ( east_din              ),
        .din_v      ( tmp_east_din_v        ),
        .din_r      ( east_din_r            ),
        .dout       ( east_buffer           ),
        .dout_v     ( tmp_east_buffer_v     ),
        .dout_r     ( east_buffer_r         )
    );

    assign east_buffer_v    = tmp_east_buffer_v && east_buffer_r;

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
        .mux_out    (   tmp_east_dout                                   )
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
        .clr        ( clr_data              ),
        .din        ( south_din             ),
        .din_v      ( tmp_south_din_v       ),
        .din_r      ( south_din_r           ),
        .dout       ( south_buffer          ),
        .dout_v     ( tmp_south_buffer_v    ),
        .dout_r     ( south_buffer_r        )
    );

    assign south_buffer_v   = tmp_south_buffer_v && south_buffer_r;

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
        .mux_out    (   tmp_south_dout                                  )
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
        .clr        ( clr_data              ),
        .din        ( west_din              ),
        .din_v      ( tmp_west_din_v        ),
        .din_r      ( west_din_r            ),
        .dout       ( west_buffer           ),
        .dout_v     ( tmp_west_buffer_v     ),
        .dout_r     ( west_buffer_r         )
    );

    assign west_buffer_v    = tmp_west_buffer_v && west_buffer_r;

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
        .mux_out    (   tmp_west_dout                                   )
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
        .clr            ( clr_data          ),
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
