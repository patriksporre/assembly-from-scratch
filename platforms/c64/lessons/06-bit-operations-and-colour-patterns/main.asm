// Assembly from Scratch
// Platform: Commodore 64
// Lesson 06: Bit operations and colour patterns
//
// This lesson introduces a simple bit operation.
//
// The C64 has 16 colour values:
//
//   $00 to $0f
//
// 16 values fit into 4 bits.
//
// This program fills the first 256 screen cells with the letter A.
// It then gives each cell a colour based on the lower 4 bits of X.
//
// The result is a repeating 16-colour pattern.

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

start:
    lda #$06                  // Load colour value $06, blue
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    ldx #$00                  // Start X at zero

fill:
    lda letter_a              // Load the screen code stored at label letter_a
    sta $0400,x               // Store it at screen memory address $0400 + X

    txa                       // Transfer X to the accumulator
    and #$0f                  // Keep only the lower 4 bits ($00 to $0f)
    sta $d800,x               // Store the result as colour at $d800 + X

    inx                       // Move to the next position
    bne fill                  // Repeat until X wraps from $ff to $00

    rts                       // Return to BASIC

letter_a:
    .byte $01                 // Screen code $01, the letter A