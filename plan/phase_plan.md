# Project phases (high level)

- Phase 0 – Architecture design 
    Deliverables: architecture specification (ISA, encodings, register set, memory map), pipeline & microarchitecture choices, acceptance tests, and an architecture-review-ready doc.

- Phase 1 – Gate-level proof
    Deliverables: NAND-only schematics & simulation for a D-FF and 1-bit ALU slice, writeup with truth tables and waveforms.

- Phase 2 – RTL primitives & verification
    Deliverables: Verilog for ALU, register file, muxes, DFF wrappers; exhaustive unit tests; cocotb/iverilog testbench harness.

- Phase 3 – Single-cycle CPU & assembler
    Deliverables: Single-cycle datapath RTL, assembler (Python), reference simulator, example programs and test vectors.

- Phase 4 – Multi-cycle / pipelined CPU
    Deliverables: Multi-cycle and/or 5-stage pipelined implementation, hazard resolution (forwarding/stalls), pipeline verification tests.

- Phase 5 – Memory subsystem & I/O
    Deliverables: RAM model, memory-mapped UART, loader/boot ROM, optional cache, FPGA integration plan.

- Phase 6 – FPGA build & demo
    Deliverables: Top wrapper, constraints, bitstream (or build scripts), demo video, measured metrics (frequency, LUT/FF/BRAM usage).

- Phase 7 – Paper, slides, repo polish & CI
    Deliverables: LaTeX paper, slides, README, CI running tests and generating coverage artifacts, final repo ready for interviews.