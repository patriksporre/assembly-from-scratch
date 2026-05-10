// Assembly from Scratch
// Platform: Commodore 64
// Lesson 18: First raster bars
//
// This lesson creates the first simple raster bar.
//
// Lessons 16 and 17 introduced raster polling and the border as a timing tool.
//
// This lesson uses the same idea to create a visible effect.
//
// The program:
//
//   waits for the start of a frame
//   waits for a chosen raster line
//   changes the border colour several times
//   returns the border to black
//   repeats forever
//
// This is still polling-based timing.
// It is not yet interrupt-driven or cycle-stable.
// But it is the first step toward classic raster effects.

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
    sei                       // Disable normal IRQ interrupts for cleaner timing

    lda #$00                  // Load colour 0, black
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

main_loop:
    jsr wait_next_frame       // Wait until a new frame begins

    lda #$00                  // Start each frame with a black border
    sta $d020                 // Store black in the border colour register

    jsr wait_bar_line         // Wait until the raster reaches the bar position

    jsr draw_raster_bar       // Draw one simple raster bar

    jmp main_loop             // Repeat forever

// -----------------------------------------------------------------------------
// Wait next frame subroutine
// -----------------------------------------------------------------------------
//
// Waits for the raster to enter the high raster range,
// then waits until it wraps back to the start of the next frame.
//
// $d012 contains the low 8 bits of the raster line.
// Bit 7 of $d011 contains the high raster bit.
//
// This avoids mistaking raster line 256 for raster line 0.
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
wait_high_raster:
    lda $d011                 // Read VIC-II control register 1
    bpl wait_high_raster      // Wait until bit 7 is set, meaning raster line >= 256

wait_new_frame:
    lda $d011                 // Read VIC-II control register 1 again
    bmi wait_new_frame        // Wait until bit 7 clears, meaning a new frame has begun

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait bar line subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 100.
//
// This is where the raster bar begins.
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

wait_bar_line:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #100                  // Compare it with raster line 100
    bne wait_bar_line         // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Draw raster bar subroutine
// -----------------------------------------------------------------------------
//
// Draws a simple raster bar by changing the border colour several times.
//
// Each colour is held briefly by a small delay.
// This creates visible horizontal bands.
//
// Input:
//
//   none
//
// Output:
//
//   border colour changed during the frame
//
// Destroys:
//
//   A
//   X
//   flags
//
// Preserves:
//
//   Y

draw_raster_bar:
    lda #$06                  // Blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$01                  // White
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$06                  // Blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$00                  // Black
    sta $d020                 // Return border to black

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Short delay subroutine
// -----------------------------------------------------------------------------
//
// Holds each colour for a short time.
//
// This is deliberately simple.
// It burns CPU time so each colour remains visible for more than a few cycles.
//
// Later lessons will replace this rough delay with cleaner raster-line timing.
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
//   X
//   flags
//
// Preserves:
//
//   A
//   Y

short_delay:
    ldx #$10                  // Delay counter

delay_loop:
    dex                       // Count down
    bne delay_loop            // Repeat until X reaches zero

    rts                       // Return to the caller