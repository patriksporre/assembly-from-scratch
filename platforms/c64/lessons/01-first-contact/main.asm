// Assembly from Scratch
// Platform: Commodore 64
// Lesson 01: First contact
//
// This is the first meaningful C64 assembly program.
//
// It changes the border colour and background colour by writing directly
// to the VIC-II colour registers.

* = $c000

start:
    lda #$06      // Load colour value $06 into the accumulator.
    sta $d020     // Store it in the VIC-II border colour register.

    lda #$02      // Load colour value $02 into the accumulator.
    sta $d021     // Store it in the VIC-II background colour register.

loop:
    jmp loop      // Stay here forever so the result remains visible.