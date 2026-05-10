// Assembly from Scratch
// Platform: Commodore 64
// Lesson 19: Cleaner raster bars
//
// This lesson improves the raster bar from Lesson 18.
//
// Lesson 18 used a short delay loop between colour changes.
//
// This lesson removes that rough delay.
// Instead, each colour change waits for a specific raster line.
//
// The program:
//
//   waits for the start of a frame
//   waits for raster line 100
//   changes the border colour
//   waits for raster line 104
//   changes the border colour
//   waits for raster line 108
//   changes the border colour
//   and so on
//
// This is still polling-based timing.
// It is not yet interrupt-driven or cycle-stable.
// But the colour changes are now tied to chosen raster lines,
// not to a rough CPU delay loop.

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

    jsr draw_raster_bar       // Draw one raster bar using raster-line waits

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
// Draw raster bar subroutine
// -----------------------------------------------------------------------------
//
// Draws a simple raster bar by changing the border colour at chosen raster lines.
//
// Unlike Lesson 18, this routine does not use a CPU delay loop.
// Each colour change waits for a specific raster line.
//
// Because this is still polling-based, the colour change may happen
// part-way through the raster line. This can make the left border less stable
// than the right border.
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
//   flags
//
// Preserves:
//
//   X
//   Y

draw_raster_bar:
wait_line_100:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #100                  // Wait for raster line 100
    bne wait_line_100         // Keep waiting until line 100 is reached

    lda #$06                  // Blue
    sta $d020                 // Set border colour

wait_line_104:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #104                  // Wait for raster line 104
    bne wait_line_104         // Keep waiting until line 104 is reached

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

wait_line_108:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #108                  // Wait for raster line 108
    bne wait_line_108         // Keep waiting until line 108 is reached

    lda #$01                  // White
    sta $d020                 // Set border colour

wait_line_112:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #112                  // Wait for raster line 112
    bne wait_line_112         // Keep waiting until line 112 is reached

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

wait_line_116:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #116                  // Wait for raster line 116
    bne wait_line_116         // Keep waiting until line 116 is reached

    lda #$06                  // Blue
    sta $d020                 // Set border colour

wait_line_120:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #120                  // Wait for raster line 120
    bne wait_line_120         // Keep waiting until line 120 is reached

    lda #$00                  // Black
    sta $d020                 // Return border to black

    rts                       // Return to the caller