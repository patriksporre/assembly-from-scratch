// Assembly from Scratch
// Platform: Commodore 64
// Lesson 24: Chained raster interrupts
//
// This lesson introduces chained raster interrupts.
//
// Lesson 23 used one raster interrupt:
//
//   line 100 -> change border colour
//
// This lesson uses two raster interrupts:
//
//   line 100 -> set border and background colour to blue
//   line 120 -> set border and background colour back to black
//
// Each interrupt handler sets up the next interrupt.
//
// This creates our first interrupt-driven raster band.
//
// This is not yet cycle-stable raster timing.
// Some flicker or partial-line transition may still be visible.
// The goal of this lesson is interrupt chaining.

// -----------------------------------------------------------------------------
// BASIC loader
// -----------------------------------------------------------------------------

* = $0801

    .word basic_next_line
    .word 10
    .byte $9e
    .text "2061"
    .byte 0

basic_next_line:
    .word 0

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

    lda #100                  // First raster interrupt line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because line 100 is below 256
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

irq_top:
    pha                       // Save A before using it

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

    lda #120                  // Next raster interrupt line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 120 is below 256
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

irq_bottom:
    pha                       // Save A before using it

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

    lda #100                  // Next raster interrupt line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 100 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the VIC-II interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt