# Details of the architecture for arachne


## Summary (high level)

1. Word size: 16 bits (data path and registers are 16-bit wide).

2. Memory: byte-addressable linear memory (each address indexes a byte). Instruction width is 16 bits (2 bytes). PC contains a byte address and must be aligned to even addresses (PC % 2 == 0). Instruction fetch reads 2 bytes at PC. After fetching a (single-word) instruction PC increments by 2. Multi-word instructions (future) may update PC accordingly.

3. Instruction width: fixed 16-bit. Opcode field: 4 bits (bits [15:12]). Multi-word encodings allowed later.

4. Registers: 8 general-purpose 16-bit registers (R0..R7) plus PC, SP, FLAGS, IR. R0 is a read-only zero register (always 0).

5. ISA formats: R-type, I-type, J-type.

6. ALU: standard integer ALU: ADD, SUB, AND, OR, XOR, SHL, SHR (logical), SAR optional later; compare/set-less-than included.

7. FLAGS: 4 flags — Z (zero), S (sign), C (carry), V (overflow). ALU operations define specific update rules (below).

8. Addressing modes (Phase 0): register, immediate, register+immediate (base+offset).

9. Memory-mapped IO: UART mapped into address space for console IO. Cache optional later.

10. Control: hardwired FSM for single-cycle and multi-cycle implementations; microcode not used initially.

11. Microarchitecture path: start with single-cycle baseline (Phase 3), later add a 5-stage pipeline (Phase 4).

12. Endianness: little-endian (multi-byte values stored low-byte first).

13. Interrupts/exceptions: minimal hooks: RESET and HALT. Interrupt support reserved for later.

14. Stack & calling convention: Simple stack with CALL/RET instructions (CALL pushes return address onto stack; RET pops). Simple calling convention for examples defined in registers.md.

## Fetch/PC semantics

- PC is a 16-bit byte address. PC must be aligned to 2 bytes (even). Fetch operation reads two bytes from memory at addresses PC and PC+1. The 16-bit instruction word is assembled as instr = memory[PC] | (memory[PC+1] << 8) because little-endian.

- After a single-word instruction, PC := PC + 2. Branch/jump/CALL/RET handlers overwrite PC as needed.

- If an instruction is defined as multi-word in the future, the assembler will emit additional words and the hardware must fetch and interpret them; for Phase 0 we only implement single-word instructions.

## Exception / undefined behavior

- Misaligned PC (odd PC) is undefined behavior in Phase 0; assembler must place code at even addresses. Hardware may raise a trap in future, but for Phase 0 treat as Fault (halt) in simulation if encountered.

- Memory accesses (LD/ST) of multi-byte data beyond memory bounds will trap or wrap depending on simulator setting; specify in tests.

## Documentation & files

- docs/isa_encoding.md — full opcode table and encodings.

- docs/memory_map.md — byte-addressable memory map and MMIO.

- docs/registers.md — regfile semantics and calling convention.

- diagrams/datapath.svg, diagrams/pipeline.svg, and diagrams/control_fsm.svg — diagrams to be produced.

- examples/isa_samples.s — sample assembly programs + expected binaries.