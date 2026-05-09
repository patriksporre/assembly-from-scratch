// Assembly from Scratch
// Platform: Commodore 64
// Lesson 04: Screen and display basics
//
// This lesson introduces the default C64 character screen.
//
// The screen is made of character cells.
// Each visible cell is controlled by one byte in screen memory.
//
// In the default C64 setup:
//
//   $0400 = row 0, column 0
//   $0401 = row 0, column 1
//   $0428 = row 1, column 0
//
// The screen is 40 columns wide.
//
// Colour is stored separately in colour RAM:
//
//   $d800 = colour for row 0, column 0
//   $d801 = colour for row 0, column 1
//   $d828 = colour for row 1, column 0

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

    lda #$01                  // Load screen code $01, the letter A
    sta $0400                 // Store it at row 0, column 0

    lda #$01                  // Load colour value $01, white
    sta $d800                 // Store it as colour for row 0, column 0

    lda #$02                  // Load screen code $02, the letter B
    sta $0401                 // Store it at row 0, column 1

    lda #$02                  // Load colour value $02, red
    sta $d801                 // Store it as colour for row 0, column 1

    lda #$03                  // Load screen code $03, the letter C
    sta $0428                 // Store it at row 1, column 0

    lda #$05                  // Load colour value $05, green
    sta $d828                 // Store it as colour for row 1, column 0

loop:
    jmp loop                  // Stay here forever so the result remains visible