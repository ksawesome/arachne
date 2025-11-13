Phase 0 acceptance checklist

Create these files & pass these checks before moving to Phase 1.

Files to exist

 docs/architecture.md (this doc)

 docs/isa_encoding.md (full encoding + examples)

 docs/memory_map.md (byte-addressable map; MMIO)

 docs/registers.md (regfile + calling convention + flags)

 diagrams/datapath.svg, diagrams/pipeline.svg, diagrams/control_fsm.svg (basic diagrams)

 examples/isa_samples.s (≥8 assembly examples)

 tools/encode_instr.py or assembler stub that maps sample assembly to hex words

Spec checks (functional)

 For every instruction in isa_encoding.md produce an example assembly line and its 16-bit hex encoding (stored in examples/expected_binaries/).

 Confirm PC increment semantics: executing a NOP increases PC by 2; encode this in a test file.

 Confirm LD/ST semantics: for LD R1, [R2 + imm4], with R2=0x0100 and imm4=0x02, simulator returns the 16-bit word at byte address 0x0102.

 Stack behavior: a small test that CALL pushes PC+2 and RET restores it (simulate in a small step-run).

 Flag semantics: tests for ADD, SUB, AND, OR, XOR showing Z/S/C/V per table.

 MMIO: write byte to 0xFF00 and observe UART transmit register semantics in simulation harness.

Review

 Peer or self sign-off: no ambiguous encoding bits, every opcode has unambiguous format and example, and alignment rules documented.