# Elastic CGRA Generator

This repository contains an architectural template to generate and simulate elastic Coarse-Grained Reconfigurable Architectures (CGRAs). The hardware design is described in SystemVerilog.

## Features

- **Generation of CGRAs**: The user can define the dimensions of the fabric and the location of inputs and outputs within the CGRA matrix.

- **CGRA Configuration Generation**: Generates the configuration word of a Processing Element to set a specific functionality. By grouping these configuration words, a CGRA bitstream can be generated to perform a Data Flow Graph (DFG).

- **Simulation**: The generated CGRAs can be simulated. Performance metrics are reported.

## Getting Started

- Install [Miniconda](https://docs.conda.io/en/latest/miniconda.html#linux-installers) as described in the link.
- Create the conda enviroment to install the repository requirements:

	```bash
	conda env create -f enviroment.yml
	```
- Activate the enviroment before using the repository:

	```bash
	conda activate cgra-gen
	```

## Using the framework

### Generate the CGRA

Change the CGRA size and define the number and position of the inputs and outputs of the CGRA in [CGRA configuration](./generator/CGRA_config.yaml). Execute the generator using make in the base path:

```bash
make generate
```

### Generate a PE configuration

Change the PE configuration parameters in [PE configuration](./bitstream/PE_config.yaml). Execute the PE configuration generator using make in the base path:

```bash
make bitstream
```

You can group these configuration words to create a CGRA bitstream, as it can be seen in [CGRA bitstream example](./tb/bitstream.h).

### Simulate the CGRA

Use the default bypassing bitstream or a custom one to test the CGRA in simulation. Execute the CGRA simulator using make in the base path:

```bash
make simulate
```

If you want to display the waveform of the simulation execute:
```bash
make waves
```

## License

This project uses the Solderpad Hardware License, Version 2.1. Please, see the [LICENSE](./LICENSE) file for more information.
