// Assembly from Scratch
// Platform: Commodore 64
// Lesson 28: Multiple raster bars on safe lines
//
// This lesson builds on Lesson 27.
//
// Lesson 27 created one stable full-width raster pulse by changing:
//
//   $d020 - border colour
//   $d021 - background colour
//
// This lesson creates several pulses by chaining the same stable double IRQ
// pattern across selected raster lines.
//
// Important:
//
// We are not compensating for badlines yet.
// We are deliberately choosing safe lines.
//
// With the normal $d011 value of $1b, badlines occur where:
//
//   raster line & 7 = 3
//
// The stable IRQ runs on:
//
//   setup line + 1
//
// So each setup line in the table is chosen so that setup_line + 1 is not
// a badline.

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

    lda #$00                  // Start with the first bar table entry
    sta current_bar           // Store current bar index

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

    ldx current_bar           // Load current bar index
    lda setup_lines,x         // Load first setup raster line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because all lines are below 256
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
// It runs on the setup line for the current bar.
//
// Its job is not to draw the visible raster bar.
// Its job is to set up a second IRQ on the next raster line,
// then wait in predictable 2-cycle NOP instructions.
//
// Input:
//
//   current_bar - index into setup_lines and bar_colours
//
// Output:
//
//   second IRQ set up on current setup line + 1
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
//   current_bar

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
// That gives us a stable cycle position for the visible colour writes.
//
// This lesson draws one bar, then schedules the next setup IRQ from a table.
//
// Input:
//
//   X - stack pointer saved by irq_setup
//   current_bar - index into setup_lines and bar_colours
//
// Output:
//
//   one full-width raster pulse drawn
//   next setup IRQ installed from setup_lines
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
//   current_bar

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
    ldx current_bar           // Load current bar index
    lda bar_colours,x         // Load colour for this bar

    sta $d020                 // Set border colour first
    sta $d021                 // Set background colour second

    ldx #$08                  // Coarse hold length for the raster pulse

bar_hold:
    dex                       // Count down
    bne bar_hold              // Repeat until X reaches zero

    nop                       // Fine adjustment: 2 cycles

    lda #$00                  // Load colour 0, black
    sta $d020                 // Restore border colour first
    sta $d021                 // Restore background colour second

// -----------------------------------------------------------------------------
// Schedule next bar
// -----------------------------------------------------------------------------

    ldx current_bar           // Load current bar index
    inx                       // Move to next bar

    lda setup_lines,x         // Load next setup line
    cmp #$ff                  // $ff marks the end of the table
    bne store_next_bar        // If not $ff, continue with this bar

    ldx #$00                  // Otherwise wrap back to the first bar
    lda setup_lines,x         // Load first setup line again

store_next_bar:
    stx current_bar           // Store next bar index

    lda #<irq_setup           // Load low byte of setup IRQ handler
    sta $fffe                 // Store low byte in IRQ vector for next bar

    lda #>irq_setup           // Load high byte of setup IRQ handler
    sta $ffff                 // Store high byte in IRQ vector for next bar

    lda setup_lines,x         // Load setup line for next bar
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because all lines are below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the second raster interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from the original first interrupt

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

// current_bar stores the active table index.
//
// It lives in normal program memory, not zero page.
// That keeps the lesson simple and avoids introducing new zero-page usage.

current_bar:
    .byte 0

// setup_lines contains the first IRQ line for each bar.
//
// The stable visible IRQ happens on setup_line + 1.
//
// With $d011 = $1b, badlines occur where:
//
//   raster line & 7 = 3
//
// These stable lines are:
//
//   93, 97, 101, 105, 109, 113
//
// None of those are badlines.

setup_lines:
    .byte 92                  // stable line 93
    .byte 108                 // stable line 109
    .byte 124                 // stable line 125
    .byte 140                 // stable line 141
    .byte 156                 // stable line 157
    .byte 172                 // stable line 173
    .byte $ff                 // terminator

// bar_colours contains one colour per setup line.
//
// C64 colour values:
//
//   1  = white
//   3  = cyan
//   6  = blue
//   14 = light blue

bar_colours:
    .byte $06                 // blue
    .byte $0e                 // light blue
    .byte $03                 // cyan
    .byte $01                 // white
    .byte $03                 // cyan
    .byte $0e                 // light blue