// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

#include <stdlib.h>
#include <iostream>
#include <cmath>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VCGRA.h"
#include "bitstream.h"

#define FORCED_MAX_SIM_TIME 20 // Set a big value if the simulation does not finish
#define MAX(x, y) (((x) > (y)) ? (x) : (y))

void simulate_cgra(VCGRA *dut, Kernel kernel_info, int data_n) {
    vluint64_t sim_time = 0;
    vluint64_t max_time = 50 + 2*kernel_info.n_pe + 2*data_n;
    int i, j, bs_count = 0;
    int data_in_count[kernel_info.n_inputs];
    vluint64_t input_timestamp[kernel_info.n_inputs][data_n];
    vluint64_t output_timestamp[kernel_info.n_outputs][data_n];
    int data_out_count[kernel_info.n_outputs];
    int latency[kernel_info.n_outputs];
    float total_latency;
    float initiation_interval[kernel_info.n_inputs], total_initiation_interval;
    float bandwidth_in[kernel_info.n_inputs], total_bandwidth_in;
    float bandwidth_out[kernel_info.n_outputs], total_bandwidth_out;
    vluint64_t first_in = 0, last_out = 0;

    for(i = 0; i < kernel_info.n_inputs; i++)
        data_in_count[i] = 0;
    for(i = 0; i < kernel_info.n_inputs; i++) 
        for(j = 0; j < data_n; j++) 
            input_timestamp[i][j] = 0;
    for(i = 0; i < kernel_info.n_outputs; i++) 
        for(j = 0; j < data_n; j++) 
            output_timestamp[i][j] = 0;
    for(i = 0; i < kernel_info.n_outputs; i++) {
        data_out_count[i] = 0;
        latency[i] = 0;
    }

    // Simulation begins
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");
    
    while(sim_time < MAX(max_time, FORCED_MAX_SIM_TIME)) {
        dut->rst_n = 1;
        dut->rst_bs = 0;
        dut->data_out_ready = 0;

        // Reset process
        if(sim_time >= 0 && sim_time < 5) {
            dut->rst_n = 0;
            dut->rst_bs = 1;
            dut->data_out_ready = 0;
        }

        // Bitstream load process
        if(dut->clk == 1 && sim_time >= 10 && sim_time < 10 + 2*kernel_info.n_pe) {
            dut->config_bitstream[0] = kernel_info.kernel[bs_count];
            dut->config_bitstream[1] = kernel_info.kernel[bs_count + 1];
            dut->config_bitstream[2] = kernel_info.kernel[bs_count + 2];
            dut->config_bitstream[3] = kernel_info.kernel[bs_count + 3];
            bs_count += 4;
        }

        if(dut->clk == 1 &&  sim_time >= 10 + 2*kernel_info.n_pe)
            for(i = 0; i < 4; i++) dut->config_bitstream[i] = 0;

        // Data process
        if(sim_time >= 20 + 2*kernel_info.n_pe) {
            // Inputs
            if(dut->clk == 1) {
                for(i = 0; i < kernel_info.n_inputs; i++) {
                    if(kernel_info.inputs[i] && (dut->data_in_ready & 1 << i) && data_in_count[i] < data_n) {
                        dut->data_in[i] = rand() % 100 - 50;
                        dut->data_in_valid |= 1 << i;
                        input_timestamp[i][data_in_count[i]++] = sim_time;
                        if(first_in == 0) first_in = sim_time;
                    }
                    else dut->data_in_valid &= ~(1 << i);
                }
            }

            // Ouputs
            for(i = 0; i < kernel_info.n_outputs; i++) {
                if(kernel_info.outputs[i]) {
                    dut->data_out_ready |= 1 << i;
                    if(dut->clk == 1 && dut->data_out_valid & 1 << i) {
                        output_timestamp[i][data_out_count[i]++] = sim_time;
                        last_out = sim_time;
                    }
                    else if(dut->clk == 1 && data_out_count[i] == 0) latency[i]++;
                }
            }
        }

        // Clock process
        dut->clk ^= 1;
        dut->clk_bs ^= 1;

        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }

    // Reports
    std::cout << "\n---------------------------------------\n";
    std::cout << "-------- CGRA Execution Report --------\n";
    std::cout << "---------------------------------------\n\n";

    //  Initiation interval
    total_initiation_interval = 0.0;
    for(i = 0; i < kernel_info.n_inputs; i++) {
        initiation_interval[i] = 0.0;
        for(j = 0; j < data_n - 1; j++) 
            initiation_interval[i] += (float)(input_timestamp[i][j+1] - input_timestamp[i][j])/2.0;
        initiation_interval[i] /= data_n - 1;
        total_initiation_interval += initiation_interval[i];
        std::cout << "Initiation interval (II) in input " << i <<": " << initiation_interval[i] << "\n";
    }
    total_initiation_interval /= kernel_info.n_inputs;
    std::cout << "--------------------------------------\n";
    std::cout << "Average Initiation Interval (II): " << total_initiation_interval << "\n\n";

    //  Latency
    total_latency = 0.0;
    for(i = 0; i < kernel_info.n_outputs; i++) {
        std::cout << "Latency in output " << i << ": " << latency[i] << "\n";
        total_latency += latency[i];
    }
    total_latency /= kernel_info.n_outputs;
    std::cout << "----------------------\n";
    std::cout << "Average latency: " << total_latency << "\n\n";

    //  Input bandwidth
    total_bandwidth_in = 0.0;
    for(i = 0; i < kernel_info.n_inputs; i++) {
        bandwidth_in[i] = 0.0;
        bandwidth_in[i] = (float)(32 * data_in_count[i]) /
            (1.0 + (float)(input_timestamp[i][data_in_count[i]-1] - input_timestamp[i][0])/2.0);
        total_bandwidth_in += bandwidth_in[i];
        std::cout << "Required bandwidth in input " << i <<": " << bandwidth_in[i] << " bits/cycle\n";
    }
    std::cout << "--------------------------------------------\n";
    std::cout << "Required input bandwidth: " << total_bandwidth_in << " bits/cycle\n\n";

    //  Output bandwidth
    total_bandwidth_out = 0.0;
    for(i = 0; i < kernel_info.n_outputs; i++) {
        bandwidth_out[i] = 0.0;
        bandwidth_out[i] = (float)(32 * data_out_count[i]) /
            (1.0 + (float)(output_timestamp[i][data_out_count[i]-1] - output_timestamp[i][0])/2.0);
        total_bandwidth_out += bandwidth_out[i];
        std::cout << "Required bandwidth in output " << i <<": " << bandwidth_out[i] << " bits/cycle\n";
    }
    std::cout << "--------------------------------------------\n";
    std::cout << "Required output bandwidth: " << total_bandwidth_out << " bits/cycle\n\n";

    //  Total bandwidth
    std::cout << "-----------------------------------\n";
    std::cout << "Required bandwidth: " << total_bandwidth_in + total_bandwidth_out << " bits/cycle\n";
    std::cout << "-----------------------------------\n";

    //  Execution cycles
    std::cout << "-----------------------------------\n";
    std::cout << "Execution cycles: " << 1 + (last_out - first_in)/2 << " cycles\n";
    std::cout << "-----------------------------------\n";

    
    std::cout << "\n---------------------------------------\n";
    std::cout << "-------- CGRA Execution Report --------\n";
    std::cout << "---------------------------------------\n\n";

    // Simulation ends
    m_trace->close();
}

int main(int argc, char** argv, char** env) {
    VCGRA *dut = new VCGRA;
    // Simulation
    simulate_cgra(dut, bypass_4x4, 100);
    delete dut;
    exit(EXIT_SUCCESS);
}
