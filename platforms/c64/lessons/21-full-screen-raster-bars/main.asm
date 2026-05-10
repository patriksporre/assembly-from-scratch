// Assembly from Scratch
// Platform: Commodore 64
// Lesson 21: Full-screen raster bars
//
// This lesson extends the raster bar from Lesson 20.
//
// Earlier raster bars changed only the border colour:
//
//   $d020
//
// This lesson changes both:
//
//   $d020 - border colour
//   $d021 - background colour
//
// This makes the raster bar span the full visible screen area,
// as long as the screen contains spaces.
//
// The timing is still polling-based.
// We are still not using raster interrupts yet.

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

    lda #$00                  // Load colour 0, black
    sta clear_colour          // Store colour used by clear_screen

    jsr clear_screen          // Clear screen memory and colour RAM

main_loop:
    jsr wait_next_frame       // Wait until a new frame begins

    lda #$00                  // Start each frame with black
    sta $d020                 // Set border colour to black
    sta $d021                 // Set background colour to black

    jsr wait_bar_start        // Wait for the raster to reach our setup line

    jsr stabilise_after_line  // Move to a more predictable point after the line changes

    jsr draw_full_bar         // Draw a full-screen raster bar

    jmp main_loop             // Repeat forever

// -----------------------------------------------------------------------------
// Clear screen subroutine
// -----------------------------------------------------------------------------
//
// Clears screen memory to spaces and initialises colour RAM.
//
// Input:
//
//   clear_colour - colour value used for colour RAM
//
// Output:
//
//   screen memory filled with spaces
//   colour RAM initialised
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
//
// Memory used:
//
//   $0400-$07ff
//   $d800-$dbff

clear_screen:
    ldx #$00                  // Start X at zero

clear:
    lda #$20                  // Load screen code $20, space
    sta $0400,x               // Clear screen page $04
    sta $0500,x               // Clear screen page $05
    sta $0600,x               // Clear screen page $06
    sta $0700,x               // Clear screen page $07

    lda clear_colour          // Load colour used for cleared cells
    sta $d800,x               // Initialise colour RAM page $d8
    sta $d900,x               // Initialise colour RAM page $d9
    sta $da00,x               // Initialise colour RAM page $da
    sta $db00,x               // Initialise colour RAM page $db

    inx                       // Move to the next position
    bne clear                 // Repeat until X wraps from $ff to $00

    rts                       // Return to the caller

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
// This is not perfect cycle-stable timing.
// It is a simple bridge between polling and proper raster timing.
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
// Draw full bar subroutine
// -----------------------------------------------------------------------------
//
// Draws a raster bar by changing both border and background colour.
//
// $d020 controls the border.
// $d021 controls the background.
//
// Because the screen is filled with spaces, changes to $d021 are visible
// across the main screen area.
//
// Input:
//
//   none
//
// Output:
//
//   border and background colour changed during the frame
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

draw_full_bar:
    lda #$06                  // Blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$01                  // White
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$06                  // Blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$00                  // Black
    sta $d020                 // Return border to black
    sta $d021                 // Return background to black

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
// It keeps the timing model consistent with Lesson 20.
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

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

clear_colour:
    .byte 0                   // Colour used when initialising colour RAM