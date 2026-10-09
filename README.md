# FPGA CPU Designs

Hands-on CPU and microcontroller designs in Verilog, built and tested on the **Sipeed Tang Nano 20K** (Gowin GW2A) using Gowin FPGA Designer.

| Project | Description | Status |
|---|---|---|
| [`4bit-cpu`](4bit-cpu/) | 4-bit CPU with PC, program memory, decoder, control unit, register file and ALU | Working on hardware |

## Roadmap

- [ ] Pipelined datapath for the 8-bit MCU (pipeline registers between stages, hazard handling)
- [ ] Turn the design into an accelerator
- [ ] Add peripherals: ADC interface, oscillator, reset pin
- [ ] C firmware for the MCU (PWM output)

## Hardware and tools

- Board: Sipeed Tang Nano 20K
- Toolchain: Gowin FPGA Designer
- Language: Verilog HDL
- Host-side helper: ESP32 (sends programs to the FPGA over UART)

## Author

Prathamesh Tambe, B.Tech ECE (AI & ML), MIT World Peace University, Pune.

## Acknowledgments

- Design advice on pipelining and the accelerator direction from a chip designer in Germany.
- README and repository structure drafted with help from Claude (Anthropic).
