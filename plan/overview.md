# Project overview (what we’ll deliver)

* A functioning CPU (custom ISA) implemented from the ground up: nand-gate → gates → ALU → register file → control → datapath → memory.
* RTL (Verilog/SystemVerilog), cycle-accurate simulator, testbench suite, assembler, small runtime programs, FPGA bitstream (optional), and a full paper + slides + demo video.
* Clear metrics: instruction set description, resource utilization (LUTs/FFs/BRAM), clock rate on FPGA, CPI/IPC for benchmarks, test coverage, and verification results.

# High-level design choices (pick one path — we can implement multiple for depth)

* **ISA size:** 16-bit machine word (good balance: expressive + easy to show binary encodings).
* **Register file:** 8–16 general registers.
* **Microarchitecture options:**

  * *Single-cycle* (simpler correctness proof), then extend to
  * *Multi-cycle* (fewer resources), then optionally
  * *5-stage pipeline* with forwarding and hazard handling (adds depth for resume).
* **Control style:** Hardwired control (combinational FSM) first; optionally add microcoded control for complex ops.
* **Memory:** Simple RAM module (word-addressable), then memory-mapped I/O (UART) and optional cache (direct-mapped) for extra credit.
* **Implementation detail:** We *start* conceptually from NAND gates (show how to make NOT/AND/OR/XOR from NAND in Logisim or a diagram), then work at gate-level for one module (e.g., 1-bit full adder built from NANDs) to demonstrate “from NAND up”, and thereafter implement at RTL level (Verilog).

# Core components to design & verify (build in this order)

1. **Boolean building blocks from NAND:** inverter, AND, OR, XOR, multiplexers, D-flipflop (edge-triggered) — show NAND-only schematics for at least one complete module (e.g., a DFF or 1-bit ALU slice).
2. **1-bit ALU slice:** produce sum, carry, logical ops, set-less-than. Verify with exhaustive tests.
3. **N-bit ALU & shifter:** combine slices, support add, sub, and, or, xor, shift logical/arithmetic.
4. **Register file:** multi-port read, single write, synchronous writes.
5. **Instruction decode / control unit:** FSM or microcode to produce control signals.
6. **Datapath:** multiplexers, PC, instruction register, ALU, memory interface.
7. **Memory module:** synchronous RAM, memory-mapped IO (UART/console). Optionally create a small cache.
8. **Assembler & toolchain:** basic assembler (Python) that emits binary images and simple linker/loader.
9. **Test programs:** hello via UART, factorial, fibonacci, small matrix multiply — used as benchmarks.
10. **Optional advanced:** pipelining, branch prediction, multiply unit (shift-add), interrupts, simple scheduler/bootloader.

# Example ISA (16-bit) — concrete starting point

(we’ll include a binary encoding table in the repo/paper)

Instruction formats (examples):

* R-type: `[4b opcode][4b rd][4b rs1][4b rs2]`
* I-type: `[4b opcode][4b rd][8b imm]`
* J-type: `[4b opcode][12b address]`

Minimal opcode set (examples):

* `0000` NOP
* `0001` ADD rd, rs1, rs2
* `0010` SUB rd, rs1, rs2
* `0011` AND rd, rs1, rs2
* `0100` OR  rd, rs1, rs2
* `0101` XOR rd, rs1, rs2  *(we’ll implement XOR using NANDs at the gate demo)*
* `0110` LDI rd, imm8
* `0111` LD  rd, [rs1 + imm4]
* `1000` ST  rd, [rs1 + imm4]
* `1001` J   addr12
* `1010` JZ  rd, addr12   (jump if rd == 0)
* `1011` CALL addr12 / `1100` RET
* `1101` PUSH rd / `1110` POP rd
* `1111` HALT

We’ll document exact encodings and assembler syntax.

# Tools & stack (practical, industry-relevant)

* **Design & prototyping (gate level):** Logisim-evolution (visualize NAND→gates→flipflop).
* **RTL & simulation:** Verilog (recommend SystemVerilog if comfortable). Use: Icarus Verilog (iverilog) for simulation, Verilator for cycle-accurate simulation, ModelSim or Questa if available.
* **Formal & test automation:** cocotb (Python testbenches), pytest, and optional SymbiYosys/SMT for simple proofs (e.g., ALU identity).
* **Synthesis / FPGA:** Xilinx Vivado (Artix-7 boards like Digilent Arty/Nexys A7) or Intel Quartus for Intel FPGAs. Use block RAM for main memory in FPGA implementation.
* **Waveform/debug:** GTKWave.
* **Assembler & tools:** Python (argparse) for assembler/loader; create a simulator (cycle-accurate for verification) in Python.
* **Documentation:** LaTeX (Overleaf), diagrams with draw.io or Mermaid. Use GitHub for repo + GitHub Actions to run tests (Icarus Verilog runs).
* **Extras:** Use GitHub Pages for a project website; make a short demo video showing UART console and waveform traces.

# Verification & testing strategy

* **Unit tests:** exhaustive tests for 1-bit ALU, register file, memory.
* **Instruction tests:** golden reference simulator (preferably in Python) and RTL tests that compare cycle-by-cycle outputs. Use cocotb to automate test vectors.
* **Regression:** CI runs after each commit (run all tests, produce coverage).
* **Waveform proof:** capture waveforms for key instructions, show correct control signals.
* **Coverage metrics:** instruction coverage (which opcodes executed), functional coverage (branches/hazards).
* **Optional formal checks:** equivalence checking between high-level model and RTL for ALU or simple instruction sequences.

# Deliverables for résumé & interview

* GitHub repo with: `rtl/`, `tb/`, `sim/`, `tools/assembler.py`, `docs/`, `fpga/` (bitstream or constraints), `benchmarks/`.
* Paper (LaTeX): Abstract → Design goals → ISA spec → Microarchitecture → Implementation details (with NAND diagrams) → Verification → Results (area, freq, CPI) → Conclusion → Future work.
* README with quickstart: run simulator, run tests, build FPGA.
* Demo video (2–5 minutes) showing UART console output, waveform debug, and a quick high-level walkthrough.
* A short slide deck for interviews.

# How to show depth on your résumé (concrete bullets)

* “Designed and implemented a custom 16-bit CPU (ISA, assembler, and assembler-toolchain) and memory subsystem in Verilog; demonstrated on Xilinx Artix-7 FPGA; verified with cocotb testbench and Verilator-based cycle-accurate simulation.”
* “Implemented ALU, register file, instruction decode, and pipeline hazard resolution; provided instruction coverage tests and formal equivalence checks for ALU.”
* Add metrics: “Supported N opcodes, achieved X MHz on Artix-7, used Y LUTs / Z BRAMs, measured average CPI = X.X on benchmark suite.”

# Repo structure suggestion

```
/cpu-project
  /rtl            # Verilog/SystemVerilog sources
  /tb             # cocotb testbenches and Python bench scripts
  /sim            # Python reference simulator & assembler
  /docs           # LaTeX paper, diagrams, ISA reference
  /fpga           # constraints, top wrapper, bitstream (if allowed)
  /benchmarks     # sample programs + expected outputs
  /scripts        # build/test scripts, CI configs
  README.md
```

# Milestones (ordered, no durations)

1. NAND → gates demo (Logisim schematic + writeup).
2. 1-bit ALU slice and exhaustive test.
3. N-bit ALU, register file, and register transfer demo (RTL skeleton).
4. Instruction formats + assembler (emit binaries).
5. Datapath + control unit — single-cycle CPU with a handful of instructions and tests.
6. Full test suite, Python reference simulator, and regression CI.
7. FPGA top wrapper + memory-mapped UART, demonstrate simple programs on board.
8. Extend to pipeline/microcode/multiply/cache (pick one for depth).
9. Paper + slides + demo video + final polished repo.

# Small technical tips / strong opinions (from experience)

* Use **Verilog + cocotb**: Verilog is concise and hiring managers expect RTL; cocotb lets you write testbenches in Python — huge productivity win.
* Show **both** a gate-level proof (one module implemented with NANDs) and RTL for everything else — that’s the most compelling “from NAND up” narrative.
* Keep the ISA intentionally *small and orthogonal* — complexity in microarchitecture (pipelining, hazards) is where you’ll impress.
* Automate everything (build, test, sim, FPGA bitstream where possible) and include CI to show reproducibility.
* Write a tight paper (3–6 pages) focusing on design decisions and verification rather than verbosely documenting every RTL file.


