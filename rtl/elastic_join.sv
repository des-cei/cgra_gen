// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

module elastic_join
    #(
        parameter int   DATA_WIDTH  = 32
    )
    (
        // Input data
        input  logic [DATA_WIDTH-1:0]   din_1,
        input  logic                    din_1_v,
        output logic                    din_1_r,
        input  logic [DATA_WIDTH-1:0]   din_2,
        input  logic                    din_2_v,
        output logic                    din_2_r,

        // Output data
        output logic [DATA_WIDTH-1:0]   dout_1,
        output logic [DATA_WIDTH-1:0]   dout_2,
        output logic                    dout_v,
        input  logic                    dout_r,

        // Configuration
        input  logic                    feedback
    );

    assign dout_1 = din_1;
    assign dout_2 = din_2;

    always_comb begin
        if (!feedback) begin
            dout_v  = din_1_v && din_2_v;
            din_1_r = dout_r && din_2_v;
            din_2_r = dout_r && din_1_v;
        end else begin
            dout_v  = din_1_v;
            din_1_r = dout_r;
            din_2_r = 1'b0;
        end
    end

endmodule
