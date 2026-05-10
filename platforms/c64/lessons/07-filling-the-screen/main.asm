// Assembly from Scratch
// Platform: Commodore 64
// Lesson 07: Filling the screen
//
// This lesson fills the full C64 character screen.
//
// A C64 text screen has:
//
//   40 columns * 25 rows = 1000 cells
//
// In the previous lesson, we filled 256 cells using X as an 8-bit offset.
//
// X can count from:
//
//   $00 to $ff
//
// That gives us 256 positions.
//
// To cover the full screen, this lesson fills four 256-byte blocks:
//
//   $0400-$04ff
//   $0500-$05ff
//   $0600-$06ff
//   $0700-$07ff
//
// This covers 1024 bytes.
// The visible screen uses the first 1000 of those bytes.

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
    sta $0400,x               // Fill screen page $04
    sta $0500,x               // Fill screen page $05
    sta $0600,x               // Fill screen page $06
    sta $0700,x               // Fill screen page $07

    txa                       // Transfer X to the accumulator
    and #$0f                  // Keep only the lower 4 bits ($00 to $0f)
    sta $d800,x               // Fill colour RAM page $d8
    sta $d900,x               // Fill colour RAM page $d9
    sta $da00,x               // Fill colour RAM page $da
    sta $db00,x               // Fill colour RAM page $db

    inx                       // Move to the next position
    bne fill                  // Repeat until X wraps from $ff to $00

    rts                       // Return to BASIC

letter_a:
    .byte $01                 // Screen code $01, the letter A