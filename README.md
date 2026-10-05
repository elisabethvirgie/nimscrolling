# [DIGITAL IC DESIGN] Midterm Exam Project: Student ID (NIM) Scrolling on TM1638

A Verilog-based FPGA project for displaying and scrolling a Student ID (NIM) on a TM1638 LED & 7-segment display module.
This project was developed as a Digital IC Design assignment and implemented on an **iCESugar V1.5 FPGA board** with an **iCE40UP5K FPGA**.

---

## Overview

This project demonstrates the implementation of a TM1638 LED & KEY display controller using **Verilog HDL**.

The FPGA communicates with the TM1638 module to control its 8-digit 7-segment display and LED indicators. The main application is to display and scroll the following Student ID:

```text
22-505938-TE-55406
```

Since the TM1638 provides only eight 7-segment digits, the NIM is displayed through a scrolling window.

The scrolling behavior can be controlled through the configured TM1638 key inputs.

---

## Features

- Verilog HDL implementation
- TM1638 LED & 7-segment display controller
- 8-digit 7-segment display
- NIM scrolling animation
- Left scrolling
- Right scrolling
- Ping-pong scrolling
- Stop / hold mode
- Adjustable scrolling interval
- LED indicators for input status
- Verilog simulation
- FPGA synthesis
- Place and route
- Bitstream generation
- FPGA programming

---

## Hardware

### FPGA Board

| Item | Specification |
|------|---------------|
| Board | iCESugar V1.5 |
| FPGA | iCE40UP5K |
| Clock | 12 MHz |
| HDL | Verilog |

### Display Module

| Item | Specification |
|------|---------------|
| Module | TM1638 LED & KEY |
| 7-Segment Display | 8 digits |
| LED Indicators | 8 LEDs |
| Interface | TM1638 serial interface |

---

## NIM

The NIM displayed by this project is:

```text
22-505938-TE-55406
```

The NIM is stored as a sequence of display characters and is shown sequentially across the eight available 7-segment digits.

---

## Scrolling Modes

The scrolling behavior is controlled using two TM1638 key inputs, referred to as **S1** and **S2**.

| S1 | S2 | Operation |
|:--:|:--:|-----------|
| 0 | 0 | Ping-pong scrolling |
| 0 | 1 | Scroll left |
| 1 | 0 | Scroll right |
| 1 | 1 | Stop / hold |

The display position is updated at approximately **1-second intervals**.

### Ping-Pong Scrolling

In ping-pong mode, the NIM moves toward one side of the display and then reverses direction when it reaches the boundary.

```text
LEFT  ←──────→  RIGHT
       ←────→
       ←────→
```

This creates a continuous back-and-forth scrolling effect.

---

## LED Indicators

The TM1638 LED indicators are used to provide visual feedback for the input state.

The LED indicators correspond to the configured switch/key status, making it easier to identify the current operating mode during testing.

---

## Project Structure

```text
nimscrolling/
│
├── build/
│   └── Generated build files and FPGA bitstream
│
├── constraints/
│   └── Constraint files
│
├── src/
│   ├── tm1638.v
│   └── top_tm1638_demo.v
│
├── Makefile
├── ice40hx8k.pcf
└── README.md
```

### File Description

| File / Directory | Description |
|------------------|-------------|
| `src/top_tm1638_demo.v` | Top-level module containing the NIM display and scrolling logic |
| `src/tm1638.v` | TM1638 communication and control module |
| `ice40hx8k.pcf` | FPGA pin constraint file |
| `Makefile` | Build, simulation, synthesis, and programming commands |
| `build/` | Generated files from the build process |
| `constraints/` | Additional project constraint files |

---

## Main Module

The top-level design is:

```verilog
module top_tm1638_demo
```

The module is responsible for:

1. Generating the scrolling timing.
2. Managing the NIM character sequence.
3. Selecting the characters visible on the eight 7-segment digits.
4. Controlling the scrolling direction.
5. Communicating with the TM1638 controller.
6. Updating the TM1638 display.
7. Handling the configured key inputs.

---

## TM1638 Interface

The TM1638 module uses three main signals:

| Signal | Function |
|--------|----------|
| `tm_cs` | Chip Select |
| `tm_clk` | Serial Clock |
| `tm_dio` | Bidirectional Data |

The interface is implemented in the `tm1638.v` module and controlled by the top-level module.

---

## FPGA Pin Assignment

The main FPGA clock and TM1638 interface are assigned through the PCF constraint file.

The pin assignments are defined in:

```text
ice40hx8k.pcf
```

Example clock assignment:

```text
set_io clk 35
```

The remaining TM1638 pins are also defined in the constraint file.

---

## Development Tools

This project uses the open-source FPGA development toolchain provided by **OSS CAD Suite**.

### Main Tools

- **Yosys** — FPGA synthesis
- **Icarus Verilog** — Verilog simulation
- **nextpnr-ice40** — Place and route
- **icepack** — Bitstream generation
- **icesprog** — FPGA programming
- **GTKWave** — Waveform visualization

---

## Build Environment

The project was developed using **OSS CAD Suite** on Windows.

Before building the project, activate the OSS CAD Suite environment:

```bat
D:\oss-cad-suite\environment.bat
```

Then navigate to the project directory:

```bat
cd /d D:\nimscrolling
```

Verify that the required tools are available:

```bat
yosys --version
iverilog -V
```

---

## Build

To build the project:

```bat
mingw32-make all
```

The build process performs the required compilation, synthesis, place-and-route, and bitstream generation steps according to the project Makefile.

Generated files are stored in the:

```text
build/
```

directory.

---

## Simulation

The Verilog design can be simulated before programming the FPGA.

Run the available testbench using:

```bat
mingw32-make test
```

For waveform-based simulation:

```bat
mingw32-make sim
```

The generated waveform can be opened using GTKWave:

```bat
gtkwave build/tm1638_tb.vcd
```

Simulation is useful for verifying the TM1638 communication and scrolling behavior before testing on the physical FPGA board.

---

## FPGA Programming

After successfully building the project, the generated bitstream can be programmed into the iCESugar FPGA board.

Using the Makefile:

```bat
mingw32-make flash
```

The bitstream can also be programmed directly using:

```bat
icesprog -w build/top_tm1638_demo.bin
```

Make sure the FPGA board is connected to the computer before executing the programming command.

---

## Implementation Flow

The complete FPGA development flow is:

```text
             Verilog HDL
                  │
                  ▼
          Icarus Verilog
                  │
                  ▼
        Simulation / Testing
                  │
                  ▼
               Yosys
                  │
                  ▼
              Synthesis
                  │
                  ▼
           nextpnr-ice40
                  │
                  ▼
           Place & Route
                  │
                  ▼
              icepack
                  │
                  ▼
          FPGA Bitstream
             (.bin)
                  │
                  ▼
             icesprog
                  │
                  ▼
          iCESugar V1.5
                  │
                  ▼
              TM1638
                  │
                  ▼
        NIM Scrolling Display
```

---

## Expected Output

After the bitstream is programmed into the FPGA, the TM1638 module displays the NIM:

```text
22-505938-TE-55406
```

The eight 7-segment digits act as a moving display window, allowing the complete NIM to be viewed through the scrolling animation.

Depending on the selected input mode, the NIM can:

- Move from left to right.
- Move from right to left.
- Continuously move back and forth.
- Remain stationary.

---

## Verification

The design was tested through both simulation and hardware implementation.

The FPGA build process includes:

```text
Verilog compilation
        ↓
Simulation
        ↓
Synthesis
        ↓
Place & Route
        ↓
Bitstream generation
        ↓
FPGA programming
        ↓
Hardware verification
```

The generated FPGA design successfully produces a programmable bitstream for the iCE40-based board.

---

## References

This project was developed using the TM1638 Verilog implementation as a starting point and adapted for the requirements of the assignment.

- TM1638 Verilog controller
- OSS CAD Suite
- Yosys
- Icarus Verilog
- nextpnr
- iCE40 FPGA toolchain

---

## Author

**Elisabeth Virginia Putri Harmadianti**

Electrical Engineering  
Universitas Gadjah Mada

---

## License

This project is intended for educational and academic purposes.
