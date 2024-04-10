// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module functional_unit
    #(
        parameter int DATA_WIDTH = 32
    )
    (
        // Clock and reset
        input  logic                    clk,
        input  logic                    rst_n,

        // Input data
        input  logic [DATA_WIDTH-1:0]   din_1,
        input  logic [DATA_WIDTH-1:0]   din_2,
        input  logic                    din_v,
        output logic                    din_r,

        // Ouput data
        output logic [DATA_WIDTH-1:0]   dout,
        output logic                    dout_v,
        input  logic                    dout_r,

        // Configuration
        input  logic                    feedback,
        input  logic [DATA_WIDTH-1:0]   initial_value,
        input  logic [15:0]             delay_value,
        input  logic [3:0]              alu_sel
    );

    logic [DATA_WIDTH-1:0]  alu_din_2, alu_dout;
    logic [15:0]            delay_count;
    logic                   initial_load, dout_v_reg, dout_v_delay;

    // ALU
    always_comb begin
        if(!feedback) begin
            alu_din_2 = din_2;
        end else begin
            alu_din_2 = dout;
        end
    end

    always_comb begin
        case (alu_sel)
            0 : alu_dout = din_1 + alu_din_2;
            1 : alu_dout = din_1 * alu_din_2;
            2 : alu_dout = din_1 - alu_din_2;
            // 3 : ...
            default : alu_dout = din_1 + alu_din_2;
        endcase
    end

    // Output
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            dout <= '0;
            dout_v_reg <= 1'b0;
            dout_v_delay <= 1'b0;
            initial_load <= 1'b0;
            delay_count <= 16'h0;
        end else begin
            // Data process
            if(!initial_load && feedback) begin
                dout <= initial_value;
                initial_load <= 1'b1;
            end else if(din_v && dout_r) begin
                dout <= alu_dout;
            end

            // Valid process
            dout_v_reg <= din_v;
            dout_v_delay <= 1'b0;

            if(feedback && din_v && dout_r && initial_load) begin
                if(delay_count + 1 == delay_value) begin
                    delay_count <= 16'h0;
                    dout_v_delay <= 1'b1;
                    initial_load <= 1'b0;
                end else begin
                    delay_count <= delay_count + 1;
                end
            end
        end
    end

    assign dout_v = feedback ? dout_v_delay : dout_v_reg;
    assign din_r = feedback ? dout_r && initial_load : dout_r;

endmodule
