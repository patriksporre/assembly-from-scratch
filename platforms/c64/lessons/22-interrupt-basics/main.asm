// Assembly from Scratch
// Platform: Commodore 64
// Lesson 22: Interrupt basics
//
// This lesson introduces a real interrupt.
//
// We do not use raster interrupts yet.
// Instead, we use CIA #1 Timer A.
//
// The main program does almost nothing.
// It sits in an infinite loop.
//
// CIA #1 Timer A counts down in the background.
// When the timer reaches zero, it requests an interrupt.
//
// The CPU then interrupts the main loop,
// jumps to irq_handler,
// acknowledges the interrupt,
// updates a software counter,
// sometimes changes the border colour,
// restores the CPU registers,
// and returns with rti.
//
// This is our first real interrupt-driven program.
//
// Timer A is a 16-bit timer.
// The largest value it can count down from is:
//
//   $ffff = 65535
//
// On a PAL C64, the CPU runs at roughly 985,000 cycles per second.
//
// So the longest Timer A period is approximately:
//
//   65536 / 985000 = 0.0665 seconds
//
// That is about 15 interrupts per second.
//
// To make the visible border colour change roughly every two seconds,
// we count about 30 timer interrupts:
//
//   0.0665 seconds * 30 = 1.995 seconds
//
// So the interrupt still fires regularly,
// but the visible work only happens when irq_counter reaches zero.

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

    lda #$ff                  // Timer A low byte
    sta $dc04                 // Store low byte in CIA #1 Timer A latch

    lda #$ff                  // Timer A high byte
    sta $dc05                 // Store high byte in CIA #1 Timer A latch

    lda #30                   // Count about 30 timer interrupts
    sta irq_counter           // This gives roughly two seconds between visible updates

    lda #%10000001            // Enable CIA #1 Timer A interrupt
    sta $dc0d                 // Bit 7 = set mask, bit 0 = Timer A interrupt

    lda #%00010001            // Start Timer A and force-load the latch
    sta $dc0e                 // CIA #1 Timer A control register

    cli                       // Enable IRQs again

main_loop:
    jmp main_loop             // Do nothing. The interrupt runs independently

// -----------------------------------------------------------------------------
// IRQ handler
// -----------------------------------------------------------------------------
//
// This routine runs automatically when CIA #1 Timer A reaches zero.
//
// The main program does not call this routine.
// The hardware interrupt system calls it.
//
// The timer interrupt fires much more often than the visible border update.
// Timer A with value $ffff fires roughly every 0.0665 seconds on a PAL C64.
// We count about 30 interrupts to get roughly two seconds:
//
//   0.0665 seconds * 30 = 1.995 seconds
//
// Input:
//
//   none
//
// Output:
//
//   irq_counter decremented
//   border colour changed when irq_counter reaches zero
//   CIA #1 Timer A interrupt acknowledged
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
//   irq_counter

irq_handler:
    pha                       // Save A on the stack

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    lda $dc0d                 // Acknowledge CIA #1 interrupt by reading interrupt register

    dec irq_counter           // Count down one timer interrupt
    bne irq_done              // If the counter is not zero, skip the visible work

    lda #30                   // Reload the software counter for roughly two seconds
    sta irq_counter           // Store it for the next interval

    inc $d020                 // Change the border colour roughly every two seconds

irq_done:
    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

irq_counter:
    .byte 30                  // Counts timer interrupts before the visible update