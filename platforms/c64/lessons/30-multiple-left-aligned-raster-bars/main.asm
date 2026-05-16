// Assembly from Scratch
// Platform: Commodore 64
// Lesson 30: Multiple left-aligned raster bars
//
// Lesson 29 created one left-aligned full-width raster bar.
//
// It did that by turning the colour on late on one raster line,
// keeping the colour active for one full PAL raster line,
// and then turning the colour off near the same horizontal position
// on the following line.
//
// This lesson applies that method to several scheduled bars.
//
// Important:
//
// We are still avoiding badlines.
// We are still using generous spacing between bars.
// We are not yet trying to make dense raster bars.
//
// This lesson also introduces self-modifying code for a precise reason:
//
//   table lookup inside the raster-critical colour-on path is too slow.
//
// Instead, the scheduling code patches the immediate operand of:
//
//   lda #colour
//
// before the next bar is drawn. The critical path then stays as fast as the
// hard-coded Lesson 29 version.

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

// -----------------------------------------------------------------------------
// Clear screen and colour RAM
// -----------------------------------------------------------------------------

    lda #$20                  // Screen code for space
    ldx #$00                  // Start at offset 0

clear_screen:
    sta $0400,x               // Clear screen page 1
    sta $0500,x               // Clear screen page 2
    sta $0600,x               // Clear screen page 3
    sta $0700,x               // Clear screen page 4
    dex                       // Count down through all 256 offset values
    bne clear_screen          // Repeat until X wraps back to 0

    lda #$00                  // Colour 0, black
    ldx #$00                  // Start at offset 0

clear_colour:
    sta $d800,x               // Clear colour RAM page 1
    sta $d900,x               // Clear colour RAM page 2
    sta $da00,x               // Clear colour RAM page 3
    sta $db00,x               // Clear colour RAM page 4
    dex                       // Count down through all 256 offset values
    bne clear_colour          // Repeat until X wraps back to 0

// -----------------------------------------------------------------------------
// Raster setup
// -----------------------------------------------------------------------------

    lda #$00                  // Start with the first bar table entry
    sta current_bar           // Store current bar index

    ldx current_bar           // Load current bar index
    lda bar_colours,x         // Load colour for the first bar
    sta bar_colour_instruction + 1
                              // Patch the immediate operand of lda #colour

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
    and #$7f                  // Clear raster high bit because all setup lines are below 256
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
// That gives us a stable cycle position.
//
// This lesson uses the Lesson 29 left-aligned bar method:
//
//   1. turn colour on late on the stable IRQ line
//   2. hold to the right-side position
//   3. keep colour active for one full PAL raster line
//   4. turn colour off near the same horizontal position on the next line
//   5. schedule the next setup IRQ from a table
//
// The colour value itself is not loaded from a table here.
// That would delay the colour-on write.
//
// Instead, the immediate operand of lda #colour is patched by the scheduling
// code after each bar.
//
// Input:
//
//   X - stack pointer saved by irq_setup
//   current_bar - index into setup_lines and bar_colours
//
// Output:
//
//   one left-aligned full-width raster bar drawn
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
//   bar_colour_instruction + 1

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
bar_colour_instruction:
    lda #$06                  // Immediate colour value patched between bars
    sta $d020                 // Turn border colour on late on the previous line
    sta $d021                 // Turn background colour on late on the previous line

// -----------------------------------------------------------------------------
// Hold to the right-side position
// -----------------------------------------------------------------------------

    ldx #$08                  // Coarse hold length from Lesson 27

bar_hold:
    dex                       // Count down
    bne bar_hold              // Repeat until X reaches zero

    nop                       // Fine adjustment: 2 cycles

// -----------------------------------------------------------------------------
// Keep the colour active for one full PAL raster line
// -----------------------------------------------------------------------------
//
// A PAL C64 raster line is 63 CPU cycles.
//
// This delay is:
//
//   ldx #$0c                  = 2 cycles
//   11 taken loops * 5 cycles = 55 cycles
//   final loop                = 4 cycles
//   nop                       = 2 cycles
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

    lda bar_colours,x         // Load colour for the next bar
    sta bar_colour_instruction + 1
                              // Patch the operand byte of lda #colour.
                              // The opcode byte remains unchanged.

    lda #<irq_setup           // Load low byte of setup IRQ handler
    sta $fffe                 // Store low byte in IRQ vector for next bar

    lda #>irq_setup           // Load high byte of setup IRQ handler
    sta $ffff                 // Store high byte in IRQ vector for next bar

    lda setup_lines,x         // Load setup line for next bar
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because all setup lines are below 256
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
// The stable IRQ happens on:
//
//   setup_line + 1
//
// The target full bar line is:
//
//   setup_line + 2
//
// With $d011 = $1b, badlines occur where:
//
//   raster line & 7 = 3
//
// These target lines are:
//
//   94, 118, 142, 166, 190
//
// None of those are badlines.
//
// The setup lines are spaced 24 lines apart.
// This leaves enough time for the explicit teaching handler to finish
// before the next scheduled IRQ.

setup_lines:
    .byte 92                  // stable line 93, target line 94
    .byte 116                 // stable line 117, target line 118
    .byte 140                 // stable line 141, target line 142
    .byte 164                 // stable line 165, target line 166
    .byte 188                 // stable line 189, target line 190
    .byte $ff                 // terminator

// bar_colours contains one colour per setup line.
//
// C64 colour values used here:
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