// Assembly from Scratch
// Platform: Commodore 64
// Lesson 16: Raster beam basics
//
// This lesson introduces the VIC-II raster beam.
//
// Earlier animation used a simple CPU delay loop.
// That made movement visible, but it was not connected to the display timing.
//
// The C64 display is drawn line by line by the VIC-II.
// The current raster line can be read from:
//
//   $d012
//
// In this lesson, we wait for specific raster lines and change the border colour.
//
// This is the beginning of raster timing.
// It is not yet stable interrupt-based timing.
// It is direct polling of the raster counter.

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
    lda #$00                  // Load colour 0, black
    sta $d021                 // Store it in the VIC-II background colour register

main_loop:
    jsr wait_next_frame       // Wait until a new frame begins

    lda #$00                  // Load colour 0, black
    sta $d020                 // Set the border colour at the top of the frame

    jsr wait_top              // Wait until the raster reaches the top section

    lda #$06                  // Load colour 6, blue
    sta $d020                 // Change the border colour while the frame is being drawn

    jsr wait_middle           // Wait until the raster reaches the middle section

    lda #$02                  // Load colour 2, red
    sta $d020                 // Change the border colour again

    jsr wait_bottom           // Wait until the raster reaches the lower section

    lda #$05                  // Load colour 5, green
    sta $d020                 // Change the border colour again

    jmp main_loop             // Repeat forever

// -----------------------------------------------------------------------------
// Wait top subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 50.
//
// Input:
//
//   none
//
// Output:
//
//   none
//
// Destroys:
//
//   A
//   flags
//
// Preserves:
//
//   X
//   Y

wait_top:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #50                   // Compare it with raster line 50
    bne wait_top              // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait middle subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 120.
//
// Input:
//
//   none
//
// Output:
//
//   none
//
// Destroys:
//
//   A
//   flags
//
// Preserves:
//
//   X
//   Y

wait_middle:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #120                  // Compare it with raster line 120
    bne wait_middle           // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait bottom subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 200.
//
// Input:
//
//   none
//
// Output:
//
//   none
//
// Destroys:
//
//   A
//   flags
//
// Preserves:
//
//   X
//   Y

wait_bottom:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #200                  // Compare it with raster line 200
    bne wait_bottom           // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait next frame subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter leaves line 0,
// then waits until it returns to line 0.
//
// This gives the main loop a cleaner frame boundary than only checking
// for $d012 to be zero once.
//
// Input:
//
//   none
//
// Output:
//
//   none
//
// Destroys:
//
//   A
//   flags
//
// Preserves:
//
//   X
//   Y

wait_next_frame:
wait_not_zero:
    lda $d012                 // Load current raster line, low 8 bits
    beq wait_not_zero         // If still line 0, wait until the raster leaves line 0

wait_zero:
    lda $d012                 // Load current raster line, low 8 bits
    bne wait_zero             // Wait until the raster returns to line 0

    rts                       // Return to the caller