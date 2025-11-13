# Phase 0 — Architecture design (detailed)

This is the canonical Phase-0 specification for the CPU project. It is authoritative for implementation and all downstream work. It contains the architecture spec, concrete encodings, exact semantics, test seeds, diagrams to produce, and a rigorous, tickable TODO list of deliverables with acceptance criteria.

---

## Summary (locked choices)

* **Word size (registers / ALU):** 16 bits.
* **Memory addressing:** **byte-addressable**. Instructions are 16 bits (2 bytes) and PC is a byte address aligned to 2.
* **Registers:** 8 general-purpose 16-bit registers `R0..R7` (R0 = constant zero), plus `PC`, `SP`, `IR`, `FLAGS`.
* **Instruction width:** fixed **16-bit** per instruction (multi-word encodings allowed later). `opcode` field is **4 bits** (bits [15:12]).
* **Instruction formats:** R-type, I-type, J-type (details below).
* **ALU:** standard integer ALU: `ADD, SUB, AND, OR, XOR, SHL, SHR, CMP` (mul/div optional later).
* **FLAGS:** Four flags — `Z` (zero), `S` (sign), `C` (carry/borrow), `V` (overflow).
* **Addressing modes (phase 0):** register; immediate; register + immediate (base+offset).
* **Memory model:** RAM + memory-mapped I/O (UART). Cache optional later.
* **Control:** Hardwired FSM for single/multi-cycle baseline. Microcode only if many complex ops are added later.
* **Microarchitecture path:** implement a **single-cycle CPU** as baseline (Phase 3) and design datapath pipeline-friendly for later 5-stage implementation (Phase 4).
* **Endianness:** **little-endian** (multi-byte values stored low byte first).
* **Interrupts:** Minimal hooks only now (RESET/HALT). Interrupt/exception support reserved for Phase 4+.
* **Stack & calling convention:** simple stack (SP grows down), `CALL`/`RET` supported. Caller-saved/callee-saved convention documented below.
* **Target:** simulation-first; synthesize to an Artix-7 / Arty-class FPGA for demo.

---

## Fetch & PC semantics

* `PC` is a **16-bit byte address**. PC must be even (PC % 2 == 0).
* Single-word fetch: read two bytes at addresses `PC` (low byte) and `PC+1` (high byte). Assemble instruction word as `instr = memory[PC] | (memory[PC+1] << 8)` (little-endian).
* After executing a single-word instruction, PC increments by **2** unless overwritten by branch/jump/CALL/RET. Multi-word instructions (future) will advance PC by their length.
* Misaligned PC (odd) is **undefined** in Phase 0: simulators should halt with a specific error; hardware should behave similarly for debug builds.

---

## Instruction formats & encodings

All instructions are 16 bits. Bit numbering `[15:0]` with 15 MSB.

### Formats

* **R-type:** `[15:12] opcode | [11:8] rd | [7:4] rs1 | [3:0] rs2`
  Used for register-register ALU ops.
* **I-type:** `[15:12] opcode | [11:8] rd | [7:0] imm8`
  Used for immediate arithmetic, `LDI`, and load/store base+offset (low nibble used for small offsets).
* **J-type:** `[15:12] opcode | [11:0] addr12`
  Used for absolute jumps/calls and conditional jumps. `addr12` is a byte address; must be even.

> Note: Register fields are 4 bits but only encodings `0x0..0x7` are valid for GP registers (high bit reserved/zero). Assemblers must error if upper bit is set.

### Opcode table (hex opcode, mnemonic, format, semantics)

```
0x0  NOP              R/I   ; no-op
0x1  ADD rd,rs1,rs2   R     ; rd := rs1 + rs2, flags Z,S,C,V
0x2  SUB rd,rs1,rs2   R     ; rd := rs1 - rs2, flags Z,S,C,V
0x3  AND rd,rs1,rs2   R     ; rd := rs1 & rs2, flags Z,S (C,V cleared)
0x4  OR  rd,rs1,rs2   R     ; rd := rs1 | rs2, flags Z,S (C,V cleared)
0x5  XOR rd,rs1,rs2   R     ; rd := rs1 ^ rs2, flags Z,S (C,V cleared)
0x6  SHL rd,rs1,imm4  I*    ; rd := rs1 << imm4 (imm4 in imm8 low nibble); C <- last bit shifted out
0x7  SHR rd,rs1,imm4  I*    ; rd := logical rs1 >> imm4; C <- last bit shifted out
0x8  LDI rd,imm8      I     ; rd := sign_extend(imm8); flags Z,S updated
0x9  LD  rd,[rs1+imm4]I     ; rd := MEM16[ rs1 + zero_extend(imm4) ] (EA must be even)
0xA  ST  rd,[rs1+imm4]I     ; MEM16[ rs1 + zero_extend(imm4) ] := rd (store 16-bit word)
0xB  J   addr12       J     ; PC := addr12
0xC  JZ  rd,addr12    J*    ; if (GR[rd] == 0) PC := addr12 else PC += 2
0xD  CALL addr12      J     ; push(PC+2); PC := addr12
0xE  RET              J/R   ; PC := pop()
0xF  HALT             R/I   ; stop execution
```

`*` indicates special encoding usage (imm4 in imm8 low nibble; JZ uses rd field for the tested register).

### Encoding examples (binary -> hex -> byte order)

* `ADD R1,R2,R3` → opcode=0x1, rd=1, rs1=2, rs2=3
  Bits: `0001 0001 0010 0011` = `0x1123`. Stored in memory as bytes `[0x23, 0x11]`.
* `LDI R4, 0x7F` → `0x84 0x7F` = word `0x847F`. Memory bytes `[0x7F, 0x84]`.
* `J 0x0100` → opcode=0xB, addr12=0x0100 -> bits: `1011 0001 0000 0000` = `0xB100`. Bytes `[0x00, 0xB1]`.

> The assembler must output bytes in little-endian order (low byte first).

---

## Registers & FLAGS (detailed)

### General-purpose registers

* `R0` — wired-zero: reads return `0x0000`. Writes are ignored. Useful for immediate add patterns and move elimination.
* `R1..R7` — general-purpose 16-bit registers.

### Special registers

* `PC` — 16-bit byte address program counter. Must be even.
* `SP` — 16-bit stack pointer (byte address). Stack grows down. Must be even.
* `IR` — 16-bit instruction register (for decode / debug).
* `FLAGS` — 4-bit register: `[Z, S, C, V]`.

### FLAGS semantics (exact)

* **Z** — set if result == 0 (16-bit).
* **S** — set if result bit15 == 1.
* **C** — arithmetic carry / borrow flag:

  * For `ADD`: set if unsigned result > 0xFFFF (carry out).
  * For `SUB`: set if borrow occurred (i.e., if rs1 < rs2 in unsigned sense).
  * For shift-left: C = last bit shifted out (bit 16 before truncate).
  * For logical ops: C cleared.
* **V** — signed overflow flag: set when signed overflow occurs (e.g., two positive additions yield negative). Cleared for logical ops.

> Default per-op update rules:
>
> * `ADD`/`SUB`: update Z, S, C, V
> * `AND`/`OR`/`XOR`: update Z, S; clear C and V
> * `SHL`/`SHR`: update Z, S, C; clear V
> * `LDI`: set Z and S; clear C and V
> * Branch/jump/CALL/RET/HALT: do **not** update FLAGS

---

## Memory map (byte-addressable; concrete)

**Default recommended layout (changeable for FPGA size):**

* `0x0000 - 0x00FF` — **Boot ROM** (256 bytes). PC reset vector = `0x0000`. Boot code recommended to initialize SP and runtime.
* `0x0100 - 0x7FFF` — **Main RAM** (default example size: 32 KiB). Use block RAM on FPGA.
* `0xFF00 - 0xFF0F` — **MMIO region** (UART + simple peripherals):

  * `0xFF00` — `UART_TX` (write-only). Write a byte to this address to transmit. Hardware reads low byte of the write.
  * `0xFF01` — `UART_STATUS` (read-only): bit0 = TX_READY (1 if ready), bit1 = RX_READY (1 if RX available).
  * `0xFF02` — `UART_RX` (read-only): read received byte.
  * `0xFF03` — `UART_CTRL` (write/read optional).
  * Remaining `0xFF04..0xFF0F` — reserved for future peripherals.
* `0xFFF0 - 0xFFFF` — reserved / vectors for future.

**Notes:** LD/ST operate on 16-bit words (two bytes). Because memory is byte-addressed, effective addresses are byte addresses. LD/ST must access two consecutive bytes at EA and EA+1; EA must be even in Phase 0 (misaligned word access undefined). MMIO addresses are single byte registers — store/loads to these must be implemented with clear semantics in the simulator.

---

## LD / ST & alignment rules

* `LD rd, [rs1 + imm4]` computes `EA = GR[rs1] + zero_extend(imm4)` (EA is byte address). Reads `mem[EA]` and `mem[EA+1]` as low and high byte to form a 16-bit value loaded into `rd`. `EA` must be even; if not, **simulator halts** with misaligned access error in Phase 0.
* `ST rd, [rs1 + imm4]` stores the 16-bit value in `rd` as two bytes: `mem[EA] := low_byte(rd)`, `mem[EA+1] := high_byte(rd)`.

> Assembler must ensure imm4 fits small displacement; for larger addresses use sequences (load immediate high/low) — documented in examples.

---

## Stack, CALL/RET & calling convention

### Stack behavior (concrete)

* Stack grows downward. SP must be even.
* **PUSH value (16-bit):** `SP := SP - 2; mem[SP] := low_byte(value); mem[SP+1] := high_byte(value)`.
* **POP value:** value := `mem[SP] | (mem[SP+1] << 8)`; `SP := SP + 2`.

### CALL / RET semantics

* `CALL addr12`: push return address `(PC + 2)` as 16-bit onto stack, then `PC := addr12`.
* `RET`: `PC := pop()` (pop a 16-bit value from stack and set PC).

### Calling convention (simple)

* **Caller-saved:** `R1`, `R2`, `R3` — the caller must preserve them if needed.
* **Callee-saved:** `R4`, `R5`, `R6` — callee must save/restore if used.
* `R7` — free / temp / optional link register (not automatically set).
* Arguments passed in `R1`, `R2`, `R3` (additional args on stack). Return value in `R1`. Caller allocates/pops stack arguments.

---

## ALU edge cases & operation details

* All arithmetic uses 16-bit two’s complement semantics for signed interpretation. Flag definitions above govern signed/unsigned behavior.
* `SHL rd, rs1, imm4`: logical left shift by `imm4` bits. Bits shifted out set `C` to last bit shifted out; result truncated to 16 bits.
* `SHR rd, rs1, imm4`: logical right shift (zero-fill) by `imm4`. `C` gets last bit shifted out. Arithmetic right shift (SAR) may be added later as an extension.
* `XOR/AND/OR` do not set `C` or `V`.

---

## Assembler syntax (starter spec)

* Case-insensitive mnemonics. One instruction per line. Comments start with `;`. Labels end with `:` and placed in front of instruction or `.data` directive.
* Directives (initial set):

  * `.org <addr>` — set assembly origin (byte-address). Must be even.
  * `.byte <val>` — emit a single byte.
  * `.word <val>` — emit a 16-bit word (little-endian).
  * `.data`, `.text` sections optional.
* Operands: `ADD R1, R2, R3`; `LDI R4, 0x10`; `LD R1, [R2 + 4]` or `LD R1, [R2 + 0x04]`; labels used in J-type targets or data references.
* Output: assembler outputs a binary file (bytes) ready to load to ROM/RAM. Also produce a `label -> address` map for debugging.

---

## Examples (concrete assembly + expected encodings)

> Assembler must output little-endian bytes. Shown are 16-bit words (hex) and byte order below.

1. `LDI R1, 0x03` — `0x8103` — bytes `[0x03, 0x81]`.
2. `LDI R2, 0x05` — `0x8205` — bytes `[0x05, 0x82]`.
3. `ADD R3, R1, R2` — `0x1312` — bytes `[0x12, 0x13]`.
4. `HALT` — `0xF000` — bytes `[0x00, 0xF0]`.
5. `J 0x0100` — `0xB100` — bytes `[0x00, 0xB1]`.
6. `ST R3, [R0 + 0x20]` — opcode 0xA, rd=3, imm8=0x20 => `0xA320` — bytes `[0x20, 0xA3]`.

(Full sample program files and `examples/expected_binaries/` will contain assembler outputs.)

---

## Verification seeds & phase-0 tests

Provide **spec-level unit tests** (not RTL yet) that will be used later for RTL verification.

Minimum required test seeds:

1. **ALU unit tests** (truth tables): given `rs1`, `rs2`, verify `ADD/SUB/AND/OR/XOR` produce expected 16-bit results and flags (Z,S,C,V) for edge cases: `0x0000`, `0xFFFF`, `0x8000`, `0x7FFF`, `carry/overflow` examples.
2. **LD/ST test**: set `R2 = 0x0100`, `mem[0x0102] = 0x34`, `mem[0x0103] = 0x12`; `LD R1, [R2 + 0x02]` should set `R1 == 0x1234`.
3. **PC increment**: `NOP; NOP` at `0x0000`, `0x0002` — executing first NOP increments PC by 2.
4. **CALL/RET test**: small program `CALL f; HALT; f: LDI R1, 0x2A; RET` — after CALL+RET, R1 == 0x2A and PC resumes. Validate stack SP updated correctly (push/pop).
5. **MMIO UART test (spec-level)**: writing byte to `0xFF00` results in UART transmit buffer capture in simulator harness (test capture).
6. **Assembler tests**: Round-trip: assemble example `.s` files and compare bytes with `examples/expected_binaries/`. Include tests for labels, `.org`, `.word`, `.byte`.

Store tests in `docs/spec-checklist.md` and `examples/` as annotated input/expected output pairs.

---

## Diagrams & schematics to produce (Phase 0)

Produce the following diagrams (SVG/PNG), placed in `diagrams/`:

1. `datapath.svg` — block datapath showing PC, IR, register file, ALU, MEM, MUXes, control lines, and where FLAGS are produced/consumed. Annotate bit widths (16-bit buses, 16-bit memory word, etc.).
2. `pipeline.svg` — IF/ID/EX/MEM/WB stage sketch showing where stage registers would be inserted (even though pipeline not implemented yet).
3. `control_fsm.svg` — state diagram for single-cycle and multi-cycle FSMs (single-cycle control can be a simple single state with combinational control; multi-cycle state map for fetch/decode/execute/mem/writeback).
4. `nand_proof.svg` — NAND-only schematic for a D flip-flop and a 1-bit XOR (show how XOR and DFF are built from NANDs). This is the canonical “from NAND up” proof artifact.

---

## Tools & repo layout (Phase 0 scaffold)

Create repo skeleton:

```
/cpu-project
  /docs
    architecture.md
    isa_encoding.md
    memory_map.md
    registers.md
    spec-checklist.md
  /diagrams
    datapath.svg
    pipeline.svg
    control_fsm.svg
    nand_proof.svg
  /examples
    isa_samples.s
    expected_binaries/
  /tools
    encode_instr.py    # Assembler-encoder stub (two-pass)
  README.md
  .github/workflows/ci.yml   # runs assembler + spec-level checks (Phase 0)
```

**Recommended toolchain** (for later phases): Logisim-evolution (gate-level visualization), Verilog/SystemVerilog, Icarus Verilog/Verilator, cocotb for testbenches, GTKWave, Vivado for FPGA synthesis. For Phase 0 only Markdown + Python assembler and diagrams are needed.

---

## Spec review questions (must be answered in docs)

These must be documented explicitly in `docs/architecture.md` or linked docs before Phase 1:

1. Why 16-bit? (brief tradeoff rationale).
2. Why fixed 16-bit / 4-bit opcode? (simplicity + room for extension).
3. Exact flag update rules per ALU op (already specified above; include examples and truth-table seeds).
4. Allowed instruction side-effects (e.g., `LD` does not write memory).
5. Misaligned access behavior (Phase 0: halt/trap).
6. How future interrupts will be vectored / where vector table will live (reserve `0xFFF0..0xFFFF`).

---

## Acceptance criteria (explicit)

Before moving from Phase 0 → Phase 1, all of the following must be true and verifiable:

* [ ] **Docs complete:** `docs/architecture.md`, `docs/isa_encoding.md`, `docs/memory_map.md`, `docs/registers.md`, and `docs/spec-checklist.md` exist and are internally consistent.
* [ ] **Diagrams produced:** `datapath.svg`, `pipeline.svg`, `control_fsm.svg`, `nand_proof.svg` added to `diagrams/`.
* [ ] **Examples ready:** `examples/isa_samples.s` has **≥ 8** sample programs (including ADD, loop, CALL/RET, UART demo) and `examples/expected_binaries/` contains assembled bytes for each.
* [ ] **Assembler stub:** `tools/encode_instr.py` (two-pass) can assemble `examples/isa_samples.s` into binary and produce little-endian bytes identical to `expected_binaries`. (This can be minimal — two-pass label resolution + encoding table.)
* [ ] **Spec tests passing (phase-0 harness):** a simple Python harness verifies the spec-level tests described in “Verification seeds & phase-0 tests”.
* [ ] **Sign-off:** You (or a designated reviewer) sign off on architecture doc and checklist. Sign-off implies no ambiguous encodings, no overlapping register definitions, and alignment/memory semantics are clear.

---

## Concrete TODO list — rigorous deliverables (tickable, numbered)

These are the **Phase 0** tasks to complete. Each item is concrete, with acceptance criteria and artifacts to attach to PR.

### 0. Repo & scaffolding

1. Initialize repository `cpu-project` with the layout above.

   * Deliverable: Git repo with empty `docs/`, `diagrams/`, `examples/`, `tools/`.
   * Acceptance: CI file present and README with Phase 0 checklist.

### 1. Architecture docs (authoritative files)

2. Create `docs/architecture.md` (this file).

   * Deliverable: Markdown file exactly matching Phase 0 spec.
   * Acceptance: File passes a linter for Markdown; no TODO markers remain.
3. Create `docs/isa_encoding.md` with full opcode table and bitfield diagrams for each format.

   * Deliverable: Table + 10 example encodings (with binary/hex and expected little-endian byte order).
   * Acceptance: Examples assemble with `tools/encode_instr.py`.
4. Create `docs/memory_map.md` documenting byte-addressable mapping and MMIO register semantics including UART handshake behavior.

   * Deliverable: Memory map with addresses and example code showing UART write.
   * Acceptance: Example UART write compiled to bytes that target `0xFF00` in expected binaries.
5. Create `docs/registers.md` containing register map, FLAGS semantics, and calling convention.

   * Deliverable: File with exact push/pop semantics and sample CALL/RET snippet.
   * Acceptance: CALL/RET sample assembled and expected SP/PC behavior documented.

### 2. Examples & expected binaries

6. Write `examples/isa_samples.s` with **at least 8** programs:

   * Boot/init (set SP), arithmetic examples, loop, factorial or fibonacci, CALL/RET demo, UART transmit demo, LD/ST example, misalignment error example.
   * Deliverable: `.s` files, each with a short README describing expected runtime behavior.
   * Acceptance: Assembler produces `examples/expected_binaries/<program>.bin` bytes matching the encodings in `docs/isa_encoding.md`.

### 3. Assembler encoder stub

7. Implement `tools/encode_instr.py` (two-pass assembler-encoder):

   * Must support labels, `.org`, `.byte`, `.word`, R/I/J formats, comment parsing, and output little-endian binary file.
   * Deliverable: Python script + unit tests for each encoding example.
   * Acceptance: Assembler produces exact expected binaries for all sample programs and exits non-zero with clear error for invalid register/odd `.org` alignments.

### 4. Diagrams & NAND proof

8. Produce `datapath.svg` (annotated with bus widths).

   * Deliverable: SVG in `diagrams/`.
   * Acceptance: Diagram includes labels for IF/ID/EX/MEM/WB positions and shows where FLAGS are set/used.
9. Produce `pipeline.svg` showing stage registers and example flow for an ADD.

   * Deliverable: SVG pipeline sketch.
   * Acceptance: Pipeline diagram shows hazards and where forwarding would be inserted (even if not implemented).
10. Produce `control_fsm.svg` showing single-cycle and multi-cycle states and transitions.

    * Deliverable: SVG.
    * Acceptance: FSM shows fetch→decode→execute→mem→writeback and control signals per state.
11. Produce `nand_proof.svg` with NAND-only schematic for DFF and 1-bit XOR, plus brief writeup `docs/nand_proof.md`.

    * Deliverable: SVG + Markdown proof.
    * Acceptance: Schematic simulated in Logisim (or equivalent) demonstrating correct behavior (attach screenshots/waveform).

### 5. Spec-level tests/harness

12. Implement a Phase-0 Python test harness `tools/spec_harness.py` that:

    * Loads `examples/expected_binaries/` and runs a small interpreter that enforces spec semantics (PC rules, LD/ST, FLAGS, CALL/RET, MMIO capturing UART).
    * Has unit tests implementing the verification seeds (ALU, LD/ST, CALL/RET, MMIO).
    * Deliverable: `spec_harness.py` + test outputs.
    * Acceptance: All spec tests pass locally and via CI.

### 6. Documentation & sign-off

13. Create `docs/spec-checklist.md` with the acceptance checklist and instructions for reviewer sign-off (who signs and what to check).

    * Deliverable: checklist doc.
    * Acceptance: reviewer signs off in PR notes or issues; checklist marked complete.

---

## Quick developer notes (strong recommendations)

* **R0 as wired-zero** simplifies many encodings (e.g., move = `ADD rd, rs, R0`). Document this pattern in `docs/idioms.md`.
* **Always validate imm sizes** in assembler and error early. For example, `LDI R1, 0x1FF` should raise “imm8 overflow” error.
* **Make misaligned access checks** explicit in simulator: a specific exception code `MISALIGNED_ACCESS` with PC and EA printed.
* **Keep single-cycle semantics simple** (all operations complete in one cycle for Phase 3). Later pipeline conversion should maintain ISA semantics via forwarding/stalls.
* **Automate**: CI runs `tools/encode_instr.py` to assemble all examples and runs `tools/spec_harness.py` to ensure Phase-0 tests pass before merging.

---


