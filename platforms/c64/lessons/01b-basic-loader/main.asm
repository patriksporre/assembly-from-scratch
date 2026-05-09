// Assembly from Scratch
// Platform: Commodore 64
// Lesson 01b: BASIC loader
//
// This lesson keeps the same visible effect as Lesson 01:
//
//   - change the border colour
//   - change the background colour
//
// The difference is how the program starts.
//
// In Lesson 01, we loaded machine code at $c000 and started it manually:
//
//   SYS 49152
//
// In this lesson, we add a tiny BASIC loader at $0801.
//
// That BASIC loader is equivalent to:
//
//   10 SYS 2061
//
// So the program can be started with:
//
//   RUN
//
// Decimal 2061 is hexadecimal $080d.
// That is where our machine code starts.

// -----------------------------------------------------------------------------
// BASIC loader
// -----------------------------------------------------------------------------
//
// A normal C64 BASIC program starts at memory address $0801.
//
// We place a tiny BASIC program here. It does not do the real work.
// It only gives BASIC a way to start our machine code.
//
// The BASIC program we create is:
//
//   10 SYS 2061
//
// BASIC stores programs as bytes in memory. We write those bytes manually
// so nothing is hidden too early.

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
//
// The BASIC loader above runs:
//
//   SYS 2061
//
// So our machine code must start at $080d.

* = $080d

start:
    lda #$06                  // Load colour value $06 into the accumulator
    sta $d020                 // Store the accumulator in the VIC-II border colour register

    lda #$02                  // Load colour value $02 into the accumulator
    sta $d021                 // Store the accumulator in the VIC-II background colour register

loop:
    jmp loop                  // Stay here forever so the result remains visible
