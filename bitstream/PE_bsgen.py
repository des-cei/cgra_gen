# Copyright 2024 CEI-UPM
# Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# Daniel Vazquez (daniel.vazquez@upm.es)

import yaml


# Configuration
with open("bitstream/PE_config.yaml", "r") as yamlfile:
    c = yaml.load(yamlfile, Loader=yaml.FullLoader)

# Processing Element
word_1 = c["fs_n"] + (c["fs_e"] << 6) + (c["fs_s"] << 12) + (c["fs_w"] << 18)
word_1 += (c["sel_n"] << 24) + (c["sel_e"] << 26) + (c["sel_s"] << 28) + (c["sel_w"] << 30)

word_2 = c["sel_pc_1"] + (c["sel_pc_2"] << 3) + (c["fs_pc"] << 6) + (c["it_rst"] << 10)
word_2 += (c["feedback"] << 26) + (c["op"] << 27)

word_3 = c["const"]

word_4 = c["position"] + (1 << 16)

print("")
print("PE bitstream, position {}:".format(c["position"]))
print("0x{:08X}, 0x{:08X}, 0x{:08X}, 0x{:08X}".format(word_1, word_2, word_3, word_4))
