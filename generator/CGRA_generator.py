# Copyright 2024 CEI-UPM
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Daniel Vazquez (daniel.vazquez@upm.es)

import yaml


# Configuration
with open("generator/CGRA_config.yaml", "r") as yamlfile:
    config = yaml.load(yamlfile, Loader=yaml.FullLoader)

rows = config['CGRA']['rows']
columns = config['CGRA']['columns']
cgra_size = rows * columns

inputs_n = config['CGRA']['inputs']['number']
inputs_pos = config['CGRA']['inputs']['positions']

if inputs_n != len(inputs_pos):
    raise Exception("Input positions length don't match the specified number of inputs")

outputs_n = config['CGRA']['outputs']['number']
outputs_pos = config['CGRA']['outputs']['positions']

if outputs_n != len(inputs_pos):
    raise Exception("Output positions length don't match the specified number of outputs")

if inputs_n + outputs_n > cgra_size:
    raise Exception("Too much inputs and/or outputs, they exceed CGRA border size")

# First template file
module_file = open("generator/templates/module.txt", "r")
ports = module_file.read().format(   str(inputs_n) + "*DATA_WIDTH-1", str(inputs_n - 1), 
                                    str(outputs_n) + "*DATA_WIDTH-1", str(outputs_n - 1), str(cgra_size - 1), 
                                    str(inputs_n - 2), str(outputs_n - 2), str(inputs_n), str(outputs_n),
                                    str(cgra_size))
module_file.close()

zero_word = "'0"
zero_bit = "1'b0"

def get_north_in(row, column):
    PE_number = column + row * rows
    for pos in inputs_pos:
        if pos[1] == "N" and int(pos[2:]) == PE_number:
            return ["wire_din", "wire_din_v", "wire_din_r", "[{}]".format(pos[0])]

    if row == 0:
        return [zero_word, zero_bit, "", ""]
    else:
        return ["ver_sn", "ver_sn_v", "ver_sn_r", "[{}][{}]".format(row-1, column)]


def get_east_in(row, column):
    PE_number = column + row * rows
    for pos in inputs_pos:
        if pos[1] == "E" and int(pos[2:]) == PE_number:
            return ["wire_din", "wire_din_v", "wire_din_r", "[{}]".format(pos[0])]

    if column == columns - 1:
        return [zero_word, zero_bit, "", ""]
    else:
        return ["hor_we", "hor_we_v", "hor_we_r", "[{}][{}]".format(row, column)]


def get_south_in(row, column):
    PE_number = column + row * rows
    for pos in inputs_pos:
        if pos[1] == "S" and int(pos[2:]) == PE_number:
            return ["wire_din", "wire_din_v", "wire_din_r", "[{}]".format(pos[0])] 

    if row == rows - 1:
        return [zero_word, zero_bit, "", ""]
    else:
        return ["ver_ns", "ver_ns_v", "ver_ns_r", "[{}][{}]".format(row, column)]


def get_west_in(row, column):
    PE_number = column + row * rows
    for pos in inputs_pos:
        if pos[1] == "W" and int(pos[2:]) == PE_number:
            return ["wire_din", "wire_din_v", "wire_din_r", "[{}]".format(pos[0])]

    if column == 0:
        return [zero_word, zero_bit, "", ""]
    else:
        return ["hor_ew", "hor_ew_v", "hor_ew_r", "[{}][{}]".format(row, column-1)]


def get_north_out(row, column):
    PE_number = column + row * rows
    for pos in outputs_pos:
        if pos[1] == "N" and int(pos[2:]) == PE_number:
            return ["wire_dout", "wire_dout_v", "wire_dout_r", "[{}]".format(pos[0])] 

    if row == 0:
        return ["", "", zero_bit, ""]
    else:
        return ["ver_ns", "ver_ns_v", "ver_ns_r", "[{}][{}]".format(row-1, column)]


def get_east_out(row, column):
    PE_number = column + row * rows
    for pos in outputs_pos:
        if pos[1] == "E" and int(pos[2:]) == PE_number:
            return ["wire_dout", "wire_dout_v", "wire_dout_r", "[{}]".format(pos[0])]

    if column == columns - 1:
        return ["", "", zero_bit, ""]
    else:
        return ["hor_ew", "hor_ew_v", "hor_ew_r", "[{}][{}]".format(row, column)]


def get_south_out(row, column):
    PE_number = column + row * rows
    for pos in outputs_pos:
        if pos[1] == "S" and int(pos[2:]) == PE_number:
            return ["wire_dout", "wire_dout_v", "wire_dout_r", "[{}]".format(pos[0])] 

    if row == rows - 1:
        return ["", "", zero_bit, ""]
    else:
        return ["ver_sn", "ver_sn_v", "ver_sn_r", "[{}][{}]".format(row, column)]


def get_west_out(row, column):
    PE_number = column + row * rows
    for pos in outputs_pos:
        if pos[1] == "W" and int(pos[2:]) == PE_number:
            return ["wire_dout", "wire_dout_v", "wire_dout_r", "[{}]".format(pos[0])]

    if column == 0:
        return ["", "", zero_bit, ""]
    else:
        return ["hor_we", "hor_we_v", "hor_we_r", "[{}][{}]".format(row, column - 1)]


# PE instantiation loop
PEs = "    // Processing element instances\n"

PE_file = open("generator/templates/instances.txt")
PE_template = PE_file.read()
PE_file.close()

for i in range(0, columns):
    for j in range(0, rows):
        PE_n = i * rows + j
        arguments = [str(PE_n)]
        arguments.extend(get_north_in(i, j))
        arguments.extend(get_east_in(i, j))
        arguments.extend(get_south_in(i, j))
        arguments.extend(get_west_in(i, j))
        arguments.extend(get_north_out(i, j))
        arguments.extend(get_east_out(i, j))
        arguments.extend(get_south_out(i, j))
        arguments.extend(get_west_out(i, j))
        PEs = PEs + PE_template.format(*arguments) + "\n\n"


# End module
endmodule = "endmodule\n"

# Write file
file = open("rtl/generated/CGRA.sv", "w")
n = "\n\n"
file.write(ports + n + PEs + endmodule)
file.close()