Memory map — CPU v0 (byte-addressable)

All addresses shown in hex. Memory is byte-addressable.

Recommended layout

0x0000 - 0x00FF — Boot ROM / Boot loader (256 bytes) — code placed here at system start. PC initial value = 0x0000 (RESET vector).

0x0100 - 0x7FFF — Main RAM (variable; for FPGA use block RAM mapped here). Typical default size for FPGA demo: 32KB (0x8000).

0xFF00 - 0xFF0F — MMIO region (peripheral registers). Reserving 0xFF00 page for IO:

0xFF00 — UART_TX (write a byte to transmit) — write low byte of 16-bit store; writing a 16-bit word writes low byte to TX and ignores high byte.

0xFF01 — UART_STATUS (read): bit0=TX_READY (1 if ready to accept next byte), bit1=RX_READY (1 if bytes available).

0xFF02 — UART_RX (read): read next received byte (low byte).

0xFF03 — UART_CONTROL (write): control flags (unused initially).

0xFFF0 - 0xFFFF — Reserved for vectors / future use.

Boot & stack

On reset, PC := 0x0000. Boot ROM should include code to initialize SP and any necessary memory. Convention: SP initial value = top of RAM: default set by boot code to 0x7FFE (aligned to even boundary). Documented in examples/isa_samples.s startup code.

Alignment

Data accesses for 16-bit LD/ST must be aligned to even addresses. Misaligned accesses are undefined in Phase 0 (sim may trap/halt).