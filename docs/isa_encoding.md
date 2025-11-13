ISA Encoding — CPU v0
Instruction formats (all 16 bits)

Bits numbering: [15:0], where bit 15 is MSB.

Fields are shown big-endian within the instruction word for readability; actual memory stores low byte first (little-endian).

R-type (register)
[15:12] opcode (4b) | [11:8] rd (4b) | [7:4] rs1 (4b) | [3:0] rs2 (4b)


Used for register-register ALU ops.

I-type (immediate)
[15:12] opcode (4b) | [11:8] rd (4b) | [7:0] imm8 (8b)


Used for immediate arithmetic, LDI, loads/stores base+offset (low nibble used), etc.

J-type (jump/call)
[15:12] opcode (4b) | [11:0] addr12 (12b)


For PC-relative or absolute jumps / calls (addr12 is byte address, must be even).

Register encoding

Registers have 4-bit fields, but we only use 3 bits for registers in R-type/I-type since we have 8 GP regs; we reserve the high bit for future use. For now rd/rs fields will only contain values 0..7.

R0..R7 map to numerical encodings 0x0..0x7. Bits [11:8] will contain the register number in the lower 3 bits; bit 3 is reserved/zero.

Opcode assignments (initial 16 opcodes reserved)
Opcode (hex)	Mnemonic	Format	Meaning / semantics
0x0	NOP	R/I	No-op
0x1	ADD rd,rs1,rs2	R	rd := rs1 + rs2
0x2	SUB rd,rs1,rs2	R	rd := rs1 - rs2
0x3	AND rd,rs1,rs2	R	bitwise AND
0x4	OR rd,rs1,rs2	R	bitwise OR
0x5	XOR rd,rs1,rs2	R	bitwise XOR
0x6	SHL rd,rs1,imm4	I*	rd := rs1 << imm4 (imm in low nibble of imm8)
0x7	SHR rd,rs1,imm4	I*	rd := rs1 >> imm4 (logical)
0x8	LDI rd,imm8	I	rd := sign-EXT(imm8) or zero-EXT (decide below)
0x9	LD rd,[rs1+imm4]	I	rd := MEM[ rs1 + zero-EXT(imm4) ] (byte-addressed, LOAD 16-bit word)
0xA	ST rd,[rs1+imm4]	I	MEM[ rs1 + zero-EXT(imm4) ] := rd (stores 16-bit word)
0xB	J addr12	J	PC := addr12
0xC	JZ rd,addr12	J*	if (rd == 0) PC := addr12
0xD	CALL addr12	J	push(PC+2); PC := addr12
0xE	RET	J/R	PC := pop();
0xF	HALT	R/I	halt CPU / stop simulation

* Notes: SHL/SHR use I-type; only lower nibble of immediate used. LDI semantics (sign vs zero extend) chosen here as sign-extend for signed immediate convenience (documented below). JZ uses rd encoded in [11:8] (lower 3 bits).

Details & semantics

Immediate LDI: LDI rd, imm8 sets rd := sign_extend(imm8) (helps small signed constants). If you prefer zero-extend for unsigned contexts, use AND or similar sequences.

LD/ST: Because memory is byte-addressable, LD/ST operate on 16-bit word values. They access two consecutive bytes at the calculated byte address. The effective address is EA = rs1 + zero_extend(imm4). For correct semantics, EA must be even; misalignment behavior is undefined in Phase 0 (sim will fault).

CALL: pushes the return address (PC + 2) onto the stack as a 16-bit value; SP := SP - 2; store low byte then high byte at memory[SP], memory[SP+1] (little-endian). Then PC := addr12.

RET: pops 16-bit address from stack at SP; PC := popped address; SP := SP + 2.

JZ: encodes rd in the rd field and addr12 in addr; if GR[rd] == 0 then PC := addr12 else PC += 2.

Example encodings (concrete)

ADD R1,R2,R3 => opcode=0x1, rd=1, rs1=2, rs2=3
Bits: 0001 0001 0010 0011 => hex 0x1123 (low byte 0x23, high byte 0x11; stored in memory as 0x23 then 0x11).

LDI R4, 0x7F => opcode=0x8, rd=4, imm8=0x7F
Bits: 1000 0100 01111111 => 0x84 0x7F => word hex 0x847F (byte layout: 0x7F, 0x84).

J 0x0100 => opcode=0xB, addr12=0x100 -> bits: 1011 0001 0000 0000 => 0xB1 0x00 -> 0xB100.

(Assembler will produce bytes in little-endian order: low byte first.)