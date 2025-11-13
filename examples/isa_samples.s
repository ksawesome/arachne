Below are example assembly snippets and their expected 16-bit encoding words (hex). Assembler must output bytes in little-endian order (low byte first).

Simple add and store

; example1: add and store
        LDI R1, 0x03        ; R1 := 3
        LDI R2, 0x05        ; R2 := 5
        ADD R3, R1, R2      ; R3 := R1 + R2
        ST  R3, [R0+0x20]   ; store R3 into memory at address 0x20
        HALT


Encodings (per instruction; hex = 16-bit word):

LDI R1,0x03 => opcode 0x8, rd=1, imm8=0x03 => bits 1000 0001 00000011 => 0x8103 (bytes 0x03, 0x81)

LDI R2,0x05 => 0x8205 (bytes 0x05, 0x82)

ADD R3,R1,R2 => opcode 0x1 rd=3 rs1=1 rs2=2 => 0001 0011 0001 0010 => 0x1312 (bytes 0x12, 0x13)

ST R3,[R0+0x20] => opcode 0xA, rd=3, imm8 = 0x20 => 0xA320 (bytes 0x20, 0xA3)

HALT => opcode 0xF => 0xF000 (bytes 0x00, 0xF0)

Loop and branch by checking zero (use JZ)

; example2: countdown loop
        LDI R1, 0x05         ; counter
loop:   SUB R1, R1, R0      ; subtract zero (acts: R1:=R1-0) placeholder; realistically you'd LDI R0,1
        JZ  R1, end
        ; do something
        J loop
end:    HALT


(We’ll refine an idiomatic loop using LDI/ADD/SUB; assembler must support labels.)

CALL / RET demo

; example3: call demo
        LDI R1, 0x00
        CALL func
        HALT

func:   LDI R1, 0x2A
        RET


Encodings: CALL with addr12 of func; assembler resolves label.

UART write (MMIO)

; example4: write 'A' (0x41) to UART_TX
        LDI R1, 0x41
        ST  R1, [R0 + 0xFF00]    ; store low byte at UART_TX address (note: integer address must be in LD/ST immediate)
        HALT


(Assembler should allow symbolic address like 0xFF00 in immediate; since LD/ST imm8 only holds 8 bits, assembler can use sequence or multi-word addressing later. For Phase 0 prefer using base register: Load address in R2 with LDI/LDI_HIGH sequence then ST.)

Simple function calling conv example (caller-saved)

Provide an example showing caller saves R1-R3 if it wants to preserve across CALL.

Memory load example

        LDI R2, 0x01
        LD R1, [R2 + 0x00] ; load word at address 0x0001 (must be aligned; example demonstrates check)


7–8) Two other small programs: fibonacci, echo from UART (read RX and write back).