// Assembly from Scratch
// Platform: Commodore 64
// Lesson 08: Zero-terminated text
//
// This lesson writes a short message to the screen.
//
// The message is stored as readable text in the source file.
// KickAssembler converts that text into C64 screen codes.
//
// The message ends with a zero byte.
//
// This is called zero-terminated text.
//
// The program copies bytes until it finds zero.

// -----------------------------------------------------------------------------
// BASIC loader
// -----------------------------------------------------------------------------
//
// This creates:
//
//   10 SYS 2061
//
// so the program can be started with:
//
//   RUN

* = $0801

    .word basic_next_line     // Pointer to where the next BASIC line would start
    .word 10                  // BASIC line number: 10
    .byte $9e                 // BASIC token for SYS
    .text "2061"              // Target address as text. 2061 decimal is $080d hexadecimal
    .byte 0                   // End of this BASIC line

basic_next_line:
    .word 0                   // End of BASIC program

// -----------------------------------------------------------------------------
// Machine code
// -----------------------------------------------------------------------------

* = $080d

.encoding "screencode_upper"  // Convert .text strings to C64 uppercase screen codes

start:
    lda #$06                  // Load colour value $06, blue
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    ldx #$00                  // Start X at zero

copy:
    lda message,x             // Load one byte from the message
    beq done                  // If the byte is zero, the message is finished

    sta $0400,x               // Store the message byte at screen memory $0400 + X

    lda #$01                  // Load colour value $01, white
    sta $d800,x               // Store it at colour RAM $d800 + X

    inx                       // Move to the next character
    jmp copy                  // Continue copying

done:
    rts                       // Return to BASIC

message:
    .text "HELLO, C64"        // Message encoded as C64 screen codes
    .byte 0                   // Zero terminator