// Assembly from Scratch
// Platform: Commodore 64
// Lesson 05: Indexed addressing
//
// This lesson introduces indexed addressing.
//
// In earlier lessons, we wrote to fixed screen addresses:
//
//   sta $0400
//   sta $0401
//   sta $0402
//
// Indexed addressing lets the X register act as an offset:
//
//   sta $0400,x
//
// This means:
//
//   store at $0400 + X
//
// If X is $00, the address is $0400.
// If X is $01, the address is $0401.
// If X is $02, the address is $0402.
//
// This lets us walk through memory with a loop.

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
    ldy #$01                  // Start Y at one (A = $01)

copy:
    tya                       // Transfer Y to the accumulator
    sta $0400,x               // Store it at screen memory address $0400 + X

    lda #$01                  // Load colour value $01, white
    sta $d800,x               // Store it at colour RAM address $d800 + X

    inx                       // Move to the next position
    iny                       // Move to the next character
    cpx #$10                  // Have we copied 16 characters?
    bne copy                  // If X is not 16, keep copying

    rts                       // Return from subroutine