// Assembly from Scratch
// Platform: Commodore 64
// Lesson 27: Proper full-width raster bars
//
// This lesson builds on Lesson 26.
//
// Lesson 26 gave us a stable raster IRQ timing marker by using a
// double IRQ pattern.
//
// This lesson uses that stable timing foundation to change both:
//
//   $d020 - border colour
//   $d021 - background colour
//
// Changing both registers lets the colour pulse appear across:
//
//   left border -> screen area -> right border
//
// This is our first proper full-width raster bar experiment.
//
// Important:
//
// A stable IRQ removes most interrupt jitter.
// It does not remove badline disruption.
//
// Therefore this lesson deliberately places the visible work on a
// non-badline. With the normal $d011 value of $1b, badlines occur
// where:
//
//   raster line & 7 = 3
//
// The stable IRQ runs on setup_line + 1.
//
// Here:
//
//   setup_line        = 92
//   stable IRQ line   = 93
//   93 & 7            = 5
//
// So the visible colour writes happen on a non-badline.

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

.const setup_line = 92        // First IRQ line. Stable IRQ runs on setup_line + 1

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
// Its job is not to draw the visible raster bar.
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
// That means the remaining timing variation is much smaller than in a
// normal raster IRQ.
//
// txs restores the stack pointer saved by irq_setup.
// This discards the extra interrupt return frame created by the second IRQ.
//
// Then we use a small PAL-timed stabilisation sequence.
// The final beq to the next instruction adds either 2 or 3 cycles,
// removing the final one-cycle difference.
//
// This lesson changes both $d020 and $d021 to create a full-width pulse.
//
// Input:
//
//   X - stack pointer saved by irq_setup
//
// Output:
//
//   stable full-width blue raster pulse drawn
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
    sta $d020                 // Set border colour first
    sta $d021                 // Set background colour second

    ldx #$08                  // Hold the colour long enough to form a visible pulse

bar_hold:
    dex                       // Count down
    bne bar_hold              // Repeat until X reaches zero

    nop                       // Fine adjustment: 2 cycles

    lda #$00                  // Load colour 0, black
    sta $d020                 // Restore border colour first
    sta $d021                 // Restore background colour second

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