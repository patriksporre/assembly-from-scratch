// Assembly from Scratch
// Platform: Commodore 64
// Lesson 25: Stable raster interrupt timing
//
// This lesson improves the chained raster interrupt from Lesson 24.
//
// Lesson 24 created an interrupt-driven raster band:
//
//   line 100 -> colour on
//   line 120 -> colour off
//
// But the visible colour transition could still flicker.
// A raster interrupt gives us a raster line, but not an exact cycle inside
// that line.
//
// This lesson introduces a simple stabilising idea:
//
//   trigger the IRQ slightly before the visible change
//   wait inside the handler for the next line boundary
//   then write the colour
//
// This is still not the final elite stable raster technique,
// but it is the first deliberate step toward stable raster interrupts.

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

    lda #<irq_top             // Load low byte of first IRQ handler address
    sta $fffe                 // Store low byte in hardware IRQ vector

    lda #>irq_top             // Load high byte of first IRQ handler address
    sta $ffff                 // Store high byte in hardware IRQ vector

    lda #99                   // Trigger one line before the visible blue change
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because line 99 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Clear any pending VIC-II raster interrupt

    lda #%00000001            // Bit 0 enables VIC-II raster interrupts
    sta $d01a                 // Enable raster interrupt source

    cli                       // Enable IRQs again

main_loop:
    jmp main_loop             // Do nothing. Raster interrupts run independently

// -----------------------------------------------------------------------------
// IRQ top handler
// -----------------------------------------------------------------------------
//
// Runs when the raster reaches line 99.
//
// This handler waits until line 100 has begun,
// then waits until line 101 begins,
// then writes the blue colour.
//
// This reduces visible jitter from IRQ entry timing.
//
// Input:
//
//   none
//
// Output:
//
//   border and background colour changed to blue
//   next raster interrupt set to line 119 and irq_bottom
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

irq_top:
    pha                       // Save A before using it

wait_top_line_100:
    lda $d012                 // Read current raster line
    cmp #100                  // Wait until line 100 is reached
    bne wait_top_line_100     // Keep waiting until raster line is 100

wait_top_line_101:
    lda $d012                 // Read current raster line
    cmp #101                  // Wait until line 101 is reached
    bne wait_top_line_101     // Keep waiting until raster line is 101

    lda #$06                  // Load colour 6, blue
    sta $d020                 // Set border colour to blue
    sta $d021                 // Set background colour to blue

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    lda #<irq_bottom          // Load low byte of next IRQ handler
    sta $fffe                 // Store low byte in IRQ vector

    lda #>irq_bottom          // Load high byte of next IRQ handler
    sta $ffff                 // Store high byte in IRQ vector

    lda #119                  // Trigger one line before the visible black change
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 119 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the VIC-II interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt

// -----------------------------------------------------------------------------
// IRQ bottom handler
// -----------------------------------------------------------------------------
//
// Runs when the raster reaches line 119.
//
// This handler waits until line 120 has begun,
// then waits until line 121 begins,
// then writes the black colour.
//
// Input:
//
//   none
//
// Output:
//
//   border and background colour changed to black
//   next raster interrupt set to line 99 and irq_top
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

irq_bottom:
    pha                       // Save A before using it

wait_bottom_line_120:
    lda $d012                 // Read current raster line
    cmp #120                  // Wait until line 120 is reached
    bne wait_bottom_line_120  // Keep waiting until raster line is 120

wait_bottom_line_121:
    lda $d012                 // Read current raster line
    cmp #121                  // Wait until line 121 is reached
    bne wait_bottom_line_121  // Keep waiting until raster line is 121

    lda #$00                  // Load colour 0, black
    sta $d020                 // Set border colour to black
    sta $d021                 // Set background colour to black

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    lda #<irq_top             // Load low byte of next IRQ handler
    sta $fffe                 // Store low byte in IRQ vector

    lda #>irq_top             // Load high byte of next IRQ handler
    sta $ffff                 // Store high byte in IRQ vector

    lda #99                   // Trigger one line before the visible blue change
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 99 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the VIC-II interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt