// Assembly from Scratch
// Platform: Commodore 64
// Lesson 03: Memory map
//
// This lesson introduces the first practical view of the C64 memory map.
//
// The CPU can write to many addresses.
// Some addresses are ordinary memory.
// Some addresses are connected to hardware.
//
// In this lesson, we write to:
//
//   $d020 - VIC-II border colour register
//   $0400 - screen memory, top-left character cell
//   $d800 - colour RAM, colour for top-left character cell
//
// This shows that different address ranges have different meanings.

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
    lda #$06                  // Load colour value $06 into the accumulator
    sta $d020                 // Store it in the VIC-II border colour register

    lda #$00                  // Load colour value $00 into the accumulator
    sta $d021                 // Store it in the VIC-II background colour register

    lda #$01                  // Load screen code $01 into the accumulator
    sta $0400                 // Store it in the top-left screen memory cell

    lda #$01                  // Load colour value $01 into the accumulator
    sta $d800                 // Store it in the colour RAM for the top-left cell

loop:
    jmp loop                  // Stay here forever so the result remains visible