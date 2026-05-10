// Assembly from Scratch
// Platform: Commodore 64
// Lesson 23: First raster interrupt
//
// This lesson introduces the first VIC-II raster interrupt.
//
// Lesson 22 used CIA #1 Timer A as the interrupt source.
//
// This lesson uses the VIC-II raster interrupt instead.
//
// The main program does almost nothing.
// It sits in an infinite loop.
//
// When the raster reaches line 100,
// the VIC-II requests an IRQ.
//
// The CPU then interrupts the main loop,
// jumps to irq_handler,
// changes the border colour,
// acknowledges the VIC-II interrupt,
// restores the CPU registers,
// and returns with rti.
//
// This is the foundation for proper C64 raster effects.

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
    sei                       // Disable IRQs while we change interrupt setup

    lda #$35                  // Keep I/O visible, but bank out BASIC and KERNAL ROM
    sta $01                   // This lets us write the hardware IRQ vector at $fffe/$ffff

    lda #$00                  // Load colour 0, black
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    lda #%01111111            // Disable all CIA #1 interrupt sources
    sta $dc0d                 // Write interrupt mask to CIA #1 interrupt control register

    lda #%01111111            // Disable all CIA #2 interrupt sources
    sta $dd0d                 // Write interrupt mask to CIA #2 interrupt control register

    lda $dc0d                 // Acknowledge any pending CIA #1 interrupt
    lda $dd0d                 // Acknowledge any pending CIA #2 interrupt

    lda #<irq_handler         // Load low byte of our IRQ handler address
    sta $fffe                 // Store low byte in the hardware IRQ vector

    lda #>irq_handler         // Load high byte of our IRQ handler address
    sta $ffff                 // Store high byte in the hardware IRQ vector

    lda #100                  // Raster line where the interrupt should happen
    sta $d012                 // Store low 8 bits of the raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear bit 7 because raster line 100 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Clear any pending VIC-II raster interrupt

    lda #%00000001            // Bit 0 enables VIC-II raster interrupts
    sta $d01a                 // Enable raster interrupt source

    cli                       // Enable IRQs again

main_loop:
    jmp main_loop             // Do nothing. The raster interrupt runs independently

// -----------------------------------------------------------------------------
// IRQ handler
// -----------------------------------------------------------------------------
//
// This routine runs automatically when the VIC-II raster reaches line 100.
//
// The main program does not call this routine.
// The VIC-II requests an interrupt,
// and the CPU jumps here through the IRQ vector at $fffe/$ffff.
//
// Input:
//
//   none
//
// Output:
//
//   border colour changed
//   VIC-II raster interrupt acknowledged
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

irq_handler:
    pha                       // Save A on the stack

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    inc $d020                 // Change border colour once per raster interrupt

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the VIC-II raster interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt