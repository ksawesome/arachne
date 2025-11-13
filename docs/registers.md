Registers & calling convention
Register file

R0 — constant zero (reads return 0; writes ignored)

R1 — general-purpose (caller-saved)

R2 — general-purpose (caller-saved)

R3 — general-purpose (caller-saved)

R4 — general-purpose (callee-saved)

R5 — general-purpose (callee-saved)

R6 — general-purpose (callee-saved)

R7 — general-purpose / link register / temp (used by caller/callee as needed)

Special registers

PC — 16-bit program counter (byte address).

SP — 16-bit stack pointer (byte address). Stack grows downward. SP must always be even-aligned.

IR — 16-bit instruction register (holds current fetched instruction for decode stage).

FLAGS — 4-bit condition flags: Z, S, C, V.

Flag semantics (update rules)

Z (Zero) — set if a result == 0 (treated on 16-bit result).

S (Sign) — set if result MSB (bit 15) == 1 (i.e., negative in two's complement).

C (Carry) — set if unsigned addition overflow (carry out of MSB) or for subtraction if borrow occurred (convention: subtraction sets C if borrow). For shifts, C is set to last bit shifted out (where applicable).

V (Overflow) — set if signed overflow occurred (e.g., adding two positives produces negative).

ALU operations will define which flags they update; by default arithmetic (ADD/SUB) update all flags; logical ops update Z and S but clear C and V.

Explicit per-op rule (Phase 0)

ADD: update C, V, Z, S.

SUB: update C (borrow), V, Z, S.

AND/OR/XOR: update Z, S; clear C and V.

SHL/SHR: update C (last bit shifted out), update Z, S; V undefined/cleared.

LDI: sets Z and S according to value; C and V cleared.

Branch/JUMP/CALL/RET/HALT: do not modify FLAGS.

Calling convention (simple)

Caller-saved registers: R1, R2, R3 — caller must preserve if needed across calls.

Callee-saved registers: R4, R5, R6 — callee must preserve (push/pop on entry/exit if used).

R7 is a temporary / optional link register. CALL pushes return address to stack; RET pops return address back to PC.

Parameters: pass in registers R1, R2, R3 (first three parameters); additional parameters via stack. Return value in R1.

Stack frame: minimal; for a callee that needs to save callee-saved registers, push them at entry and pop at exit.

Stack behavior (concrete)

PUSH 16-bit value: SP := SP - 2; MEM[SP] := low byte; MEM[SP+1] := high byte.

POP 16-bit value: value := MEM[SP] | (MEM[SP+1]<<8); SP := SP + 2.