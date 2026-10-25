# FPGA CPU Designs

Hands-on CPU and microcontroller designs in Verilog, built and tested on the **Sipeed Tang Nano 20K** (Gowin GW2A) using Gowin FPGA Designer.

| Project | Description | Status |
|---|---|---|
| [`4bit-cpu`](4bit-cpu/) | 4-bit CPU with PC, program memory, decoder, control unit, register file and ALU | Working on hardware |
| [`8bit-pipelined-mcu`](8bit-pipelined-mcu/) | 8-bit pipelined CPU with forwarding, UART program loader and two timers with four compare channels | In progress |

## 8-bit pipelined MCU

### Architecture

- 8-bit datapath, 16-bit instructions, four general-purpose registers
- Pipeline: fetch, decode, execute, memory, write-back, with a pipeline register between every stage
- Data forwarding from the MEM and WB stages into the ALU inputs
- Zero and carry flags, updated by ALU instructions
- Program memory is written at runtime over UART, so no re-synthesis is needed to change the program
- Clock: 27 MHz on-board oscillator

### Instruction format

```
[15:12] opcode | [11:10] rd | [9:8] rs | [7:0] value
```

| Opcode | Operation |
|---|---|
| `0000` to `0011` | ALU operation, writes `rd`, updates flags |
| `0100` | Load 8-bit immediate into `rd` |
| `0101` | ALU operation without write-back |
| `0110` | NOP |
| `0111` | Start timer (`rd` = 0: timer 0, 1: timer 1, 2 or 3: both) |
| `1000` | Set compare value (`rd` selects comparator 0 to 3) |
| `1001` | Set compare value of comparator 1 |

### Peripherals

Two free-running 26-bit timers, each with two 8-bit comparators (four comparators in total).

| Comparator | Timer | Compares against | Output |
|---|---|---|---|
| 0 | Timer 0 | counter bits [15:8] (PWM) | `leds[11]` |
| 1 | Timer 0 | counter top 8 bits (slow blink) | `leds[10]` |
| 2 | Timer 1 | counter bits [15:8] (PWM) | `timer1_out[0]` |
| 3 | Timer 1 | counter top 8 bits (slow blink) | `timer1_out[1]` |

### UART program loader

- 115200 baud, 8-bit data
- Each instruction is sent as three bytes: write address, high byte, low byte
- The on-board LED lights briefly on every program memory write

### Outputs

| Signal | Meaning |
|---|---|
| `leds[7:0]` | Last write-back result |
| `leds[8]` | Zero flag |
| `leds[9]` | Carry flag |
| `leds[10]` | Timer 0 blink output |
| `leds[11]` | Timer 0 PWM output |
| `timer1_out[1:0]` | Timer 1 blink and PWM outputs |
| `onboard_led` | Program write indicator |

## Roadmap

- [x] Pipelined datapath for the 8-bit MCU (pipeline registers between stages, forwarding)
- [x] UART program loader
- [x] Two timers with four compare channels
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
