// Assembly from Scratch
// Platform: Commodore 64
// Lesson 29: Left-aligned raster bar
//
// Lesson 28 gave us multiple stable bars, but they started too far to the
// right because the colour writes happened after the IRQ entry and
// stabilisation overhead.
//
// This lesson solves the next problem:
//
//   how do we make a raster bar begin at the left side?
//
// The answer in this lesson is:
//
//   set the colour near the end of the previous raster line,
//   keep it active across the next raster line,
//   then restore the colour near the same horizontal position one line later.
//
// This means the target line starts with the colour already active.
//
// We are still avoiding badlines. With the normal $d011 value of $1b,
// badlines occur where:
//
//   raster line & 7 = 3
//
// This lesson uses:
//
//   setup line        = 92
//   stable IRQ line   = 93
//   target bar line   = 94
//
// The colour is turned on late on line 93.
// Line 94 then begins with the colour already active.

// -----------------------------------------------------------------------------
// BASIC loader
// -----------------------------------------------------------------------------

* = $0801

    .word basic_next_line     // Pointer to where the next BASIC line would start
    .word 10                  // BASIC line number: 10
    .byte $9e                 // BASIC token for SYS
    .text "2061"              // Target address as text. 2061 decimal is $080d hexadecimal
    .byte 0                   // End of this BASIC line

basic_next_line:
    .word 0                   // End of BASIC program

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------

.const setup_line = 92        // First IRQ line. Stable IRQ runs on line 93.
                              // The visible full line we are preparing is line 94.

// -----------------------------------------------------------------------------
// Machine code
// -----------------------------------------------------------------------------

* = $080d

start:
    sei                       // Disable IRQs while we change interrupt setup

    lda #$35                  // Keep I/O visible, but bank out BASIC and KERNAL ROM
    sta $01                   // This lets us write the hardware IRQ vector at $fffe/$ffff

    lda #$00                  // Load colour 0, black
    sta $d020                 // Set border colour to black
    sta $d021                 // Set background colour to black

    lda #%01111111            // Disable all CIA #1 interrupt sources
    sta $dc0d                 // Write interrupt mask to CIA #1 interrupt control register

    lda #%01111111            // Disable all CIA #2 interrupt sources
    sta $dd0d                 // Write interrupt mask to CIA #2 interrupt control register

    lda $dc0d                 // Acknowledge any pending CIA #1 interrupt
    lda $dd0d                 // Acknowledge any pending CIA #2 interrupt

    lda #<irq_setup           // Load low byte of setup IRQ handler
    sta $fffe                 // Store low byte in hardware IRQ vector

    lda #>irq_setup           // Load high byte of setup IRQ handler
    sta $ffff                 // Store high byte in hardware IRQ vector

    lda #setup_line           // First IRQ line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because setup_line is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Clear any pending VIC-II raster interrupt

    lda #%00000001            // Bit 0 enables VIC-II raster interrupts
    sta $d01a                 // Enable raster interrupt source

    cli                       // Enable IRQs again

main_loop:
    jmp main_loop             // Do nothing. The raster IRQs run independently

// -----------------------------------------------------------------------------
// Setup IRQ handler
// -----------------------------------------------------------------------------
//
// This is the first IRQ in the double IRQ pattern.
//
// It runs on setup_line.
//
// Its job is not to draw the visible bar.
// Its job is to set up a second IRQ on the next raster line,
// then wait in predictable 2-cycle NOP instructions.
//
// Input:
//
//   none
//
// Output:
//
//   second IRQ set up on setup_line + 1
//
// Destroys:
//
//   handled by the second IRQ path
//
// Preserves:
//
//   restored by the second IRQ path
//
// Memory used:
//
//   stack page $0100-$01ff

irq_setup:
    pha                       // Save A on the stack

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    lda #<irq_stable          // Load low byte of stable IRQ handler
    sta $fffe                 // Store low byte in IRQ vector

    lda #>irq_stable          // Load high byte of stable IRQ handler
    sta $ffff                 // Store high byte in IRQ vector

    inc $d012                 // Set next raster IRQ to the following raster line

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the first raster interrupt

    tsx                       // Copy the current stack pointer into X.
                              // The second IRQ will push another return frame.
                              // irq_stable will restore this stack pointer with txs.

    cli                       // Allow the second IRQ to interrupt this handler

    nop                       // Wait for the second IRQ using 2-cycle instructions
    nop                       // This reduces the next IRQ's jitter to about one cycle
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

setup_wait:
    jmp setup_wait            // We should never reach this if the second IRQ fires

// -----------------------------------------------------------------------------
// Stable IRQ handler
// -----------------------------------------------------------------------------
//
// This is the second IRQ in the double IRQ pattern.
//
// It interrupts irq_setup while irq_setup is executing NOP instructions.
// That gives us a stable cycle position.
//
// In Lesson 27, we turned the colour on and off within the same raster line.
// That made the pulse stable, but it started too far to the right.
//
// In this lesson, we turn the colour on late on the previous line,
// keep it active for one full raster line,
// then turn it off near the same horizontal position one line later.
//
// Input:
//
//   X - stack pointer saved by irq_setup
//
// Output:
//
//   left-aligned full-width raster bar prepared for the next line
//   next setup IRQ installed for the next frame
//
// Destroys:
//
//   none, after restoration
//
// Preserves:
//
//   A
//   X
//   Y
//   flags are restored by rti
//
// Memory used:
//
//   stack page $0100-$01ff

irq_stable:
    txs                       // Restore stack pointer from before the second IRQ frame

    ldx #$08                  // PAL timing delay used before the raster compare

stable_delay:
    dex                       // Count down
    bne stable_delay          // Loop until X reaches zero

    bit $00                   // Waste 3 cycles using zero-page BIT.
                              // We do not care about the flags here.

    lda $d012                 // Read current raster line
    cmp $d012                 // Compare with raster line again at a critical point

    beq stable_point          // Branch to the next instruction.
                              // Taken = 3 cycles, not taken = 2 cycles.
                              // This removes the final one-cycle difference.

stable_point:
    lda #$06                  // Load colour 6, blue
    sta $d020                 // Turn border blue late on the previous line
    sta $d021                 // Turn background blue late on the previous line

// -----------------------------------------------------------------------------
// Hold until the same horizontal position on the next raster line
// -----------------------------------------------------------------------------

    ldx #$08                  // Coarse delay to reach the right side of this line

bar_hold:
    dex                       // Count down
    bne bar_hold              // Repeat until X reaches zero

    nop                       // Fine adjustment from Lesson 27

// At this point, Lesson 27 would restore the colour.
// Instead, we keep the colour active for one full PAL raster line.
//
// A PAL C64 raster line is 63 CPU cycles.
// This delay is:
//
//   ldx #$0c      = 2 cycles
//   11 taken loops * 5 cycles = 55 cycles
//   final loop    = 4 cycles
//   nop           = 2 cycles
//
// Total:
//
//   2 + 55 + 4 + 2 = 63 cycles
//
// This returns us to approximately the same horizontal position
// on the next raster line.

    ldx #$0c                  // One full PAL raster line delay

one_line_delay:
    dex                       // Count down
    bne one_line_delay        // Repeat until X reaches zero

    nop                       // Complete the 63-cycle PAL line delay

    lda #$00                  // Load colour 0, black
    sta $d020                 // Restore border colour near the right side of the target line
    sta $d021                 // Restore background colour near the right side of the target line

// -----------------------------------------------------------------------------
// Restore setup IRQ for the next frame
// -----------------------------------------------------------------------------

    lda #<irq_setup           // Load low byte of setup IRQ handler
    sta $fffe                 // Store low byte in IRQ vector for next frame

    lda #>irq_setup           // Load high byte of setup IRQ handler
    sta $ffff                 // Store high byte in IRQ vector for next frame

    lda #setup_line           // Restore first IRQ line for next frame
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because setup_line is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the second raster interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from the original first interrupt