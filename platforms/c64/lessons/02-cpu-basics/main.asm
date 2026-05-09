// Assembly from Scratch
// Platform: Commodore 64
// Lesson 02: CPU basics
//
// This lesson introduces the first working mental model of the 6510 CPU.
//
// The CPU has small internal registers.
// Instructions move values into and out of those registers.
// Some instructions change values.
// Some instructions change what code runs next.
//
// This program changes the border colour repeatedly by using the accumulator
// and the X register.

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
    ldx #$00                  // Load the immediate value $00 into the X register

colour_loop:
    txa                       // Transfer X to the accumulator
    sta $d020                 // Store the accumulator in the border colour register
    inx                       // Increment X by one
    jmp colour_loop           // Repeat forever