// Assembly from Scratch
// Platform: Commodore 64
// Lesson 20: Stable raster timing
//
// This lesson improves the raster bar from Lesson 19.
//
// Lesson 19 waited for specific raster lines and changed the border colour.
// That was cleaner than a rough delay loop, but the left border could still
// flicker because the colour write happened at slightly different horizontal
// positions inside the raster line.
//
// This lesson introduces a more controlled timing pattern:
//
//   wait for a raster line
//   wait until the raster has moved to the next line
//   run a small fixed delay
//   write colours with predictable timing
//
// This is still not full interrupt-driven stable raster timing.
// But it is the next step toward understanding why cycle timing matters.

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

    jsr wait_bar_start        // Wait for the raster to reach our setup line

    jsr stabilise_after_line  // Move to a more predictable point after the line changes

    jsr draw_stable_bar       // Draw a bar using fixed instruction timing

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
// Wait bar start subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 99.
//
// The bar itself will begin shortly after this.
// We use this line as a setup line before drawing.
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

wait_bar_start:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #99                   // Wait for setup raster line 99
    bne wait_bar_start        // Keep waiting until line 99 is reached

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Stabilise after line subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster leaves the setup line,
// then burns a small fixed number of cycles.
//
// The first wait synchronises us to a line change.
// The NOPs then move the colour writes a little further into the next line.
//
// This is not a perfect stabiliser.
// It is a simple first step toward cycle-aware timing.
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

stabilise_after_line:
wait_leave_line:
    lda $d012                 // Load current raster line
    cmp #99                   // Are we still on setup line 99?
    beq wait_leave_line       // If yes, wait until the raster leaves it

    nop                       // Fixed 2-cycle delay
    nop                       // Fixed 2-cycle delay
    nop                       // Fixed 2-cycle delay
    nop                       // Fixed 2-cycle delay

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Draw stable bar subroutine
// -----------------------------------------------------------------------------
//
// Draws a raster bar using fixed instruction timing instead of waiting
// for each raster line.
//
// This means the colour changes are spaced by known instruction sequences.
//
// The bar is still not perfect, but it should be more horizontally stable
// than the line-polling version from Lesson 19.
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

draw_stable_bar:
    lda #$06                  // Blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$01                  // White
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$06                  // Blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$00                  // Black
    sta $d020                 // Return border to black

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait four lines subroutine
// -----------------------------------------------------------------------------
//
// Burns roughly the amount of CPU time taken by a few raster lines.
//
// A PAL C64 raster line is 63 cycles.
// Four raster lines are roughly 252 cycles.
//
// This simple routine is not cycle-perfect.
// It is deliberately close enough to show how fixed code time can replace
// repeated polling for each colour band.
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

wait_four_lines:
    ldx #$28                  // Delay counter chosen to approximate a few raster lines

wait_four_lines_loop:
    dex                       // Count down
    bne wait_four_lines_loop  // Repeat until X reaches zero

    rts                       // Return to the caller