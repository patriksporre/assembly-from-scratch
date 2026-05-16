// Assembly from Scratch
// Platform: Commodore 64
// Lesson 31: Phase-safe dense raster bars
//
// Lesson 30 created several left-aligned full-width raster bars.
//
// This lesson makes two important steps:
//
//   1. The bars are placed more densely.
//   2. The whole bar stack moves vertically.
//
// The key rule is:
//
//   The movement must preserve the known-good raster phase.
//
// For the current routine, the working phase is:
//
//   setup line  & 7 = 4
//   stable line & 7 = 5
//   target line & 7 = 6
//
// With the normal $d011 value of $1b, badlines occur where:
//
//   raster line & 7 = 3
//
// So the setup, stable, and target lines all avoid badlines.
//
// The first movement step is deliberately simple:
//
//   move the whole stack in 8-line steps
//
// This preserves the same phase because adding 8 does not change
// the lower three bits of the raster line.

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

    jsr rebuild_setup_lines   // Build initial setup line table from base and offsets

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
    lda setup_lines,x         // Load first generated setup raster line
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
// The colour value is patched before this critical point. That lets the
// visible colour-on path stay short and cycle-stable.
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
//   setup_lines
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
    cmp #$ff                  // $ff marks the end of the generated setup table
    bne store_next_bar        // If not $ff, continue with this bar

    jsr update_bar_movement   // We have finished the stack for this frame
    jsr rebuild_setup_lines   // Rebuild setup lines for the next frame

    ldx #$00                  // Wrap back to the first bar
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
// Rebuild setup line table
// -----------------------------------------------------------------------------
//
// Builds setup_lines from:
//
//   base_setup_line + setup_offsets
//
// This lets the bar stack move while preserving the phase relationship.
//
// Input:
//
//   base_setup_line
//   setup_offsets
//
// Output:
//
//   setup_lines rebuilt
//
// Destroys:
//
//   A
//   X
//
// Preserves:
//
//   Y
//
// Memory used:
//
//   setup_lines

rebuild_setup_lines:
    ldx #$00                  // Start with first offset

rebuild_loop:
    lda setup_offsets,x       // Load offset
    cmp #$ff                  // Check for terminator
    beq rebuild_done          // If $ff, end the generated table

    clc                       // Clear carry before addition
    adc base_setup_line       // Add base setup line
    sta setup_lines,x         // Store generated setup line

    inx                       // Move to next entry
    jmp rebuild_loop          // Continue

rebuild_done:
    sta setup_lines,x         // Copy $ff terminator into setup_lines
    rts                       // Return to caller

// -----------------------------------------------------------------------------
// Update moving bar base
// -----------------------------------------------------------------------------
//
// Moves the whole raster bar stack in 8-line steps.
//
// This deliberately preserves:
//
//   setup line  & 7 = 4
//   stable line & 7 = 5
//   target line & 7 = 6
//
// because adding or subtracting 8 does not change the lower three bits.
//
// The movement bounces between base setup lines 92 and 124.
//
// Input:
//
//   base_setup_line
//   move_delta
//   move_counter
//
// Output:
//
//   base_setup_line updated every few frames
//   move_delta reversed at the movement bounds
//
// Destroys:
//
//   A
//
// Preserves:
//
//   X
//   Y
//
// Memory used:
//
//   base_setup_line
//   move_delta
//   move_counter

update_bar_movement:
    inc move_counter          // Count frames

    lda move_counter          // Load frame counter
    cmp #$10                  // Move every 16 frames
    bne movement_done         // If not time yet, do nothing

    lda #$00                  // Reset movement counter
    sta move_counter

    lda base_setup_line       // Load current base line
    clc                       // Clear carry before adding signed delta
    adc move_delta            // Add +8 or -8
    sta base_setup_line       // Store new base line

    cmp #124                  // Lower movement bound reached?
    bne check_upper_bound     // If not, check the other bound

    lda #$f8                  // Change direction to -8
    sta move_delta
    rts                       // Return to caller

check_upper_bound:
    cmp #92                   // Upper movement bound reached?
    bne movement_done         // If not, keep current direction

    lda #$08                  // Change direction to +8
    sta move_delta

movement_done:
    rts                       // Return to caller

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

// current_bar stores the active table index.
//
// It lives in normal program memory, not zero page.

current_bar:
    .byte 0

// base_setup_line is the first setup line for the raster bar stack.
//
// This value must keep:
//
//   base_setup_line & 7 = 4
//
// so that the generated setup/stable/target lines stay in the known-good
// phase.

base_setup_line:
    .byte 92                  // First setup line for the moving bar stack

// move_delta controls movement direction.
//
//   $08 = move down by 8 raster lines
//   $f8 = move up by 8 raster lines, because $f8 is -8 in 8-bit wraparound

move_delta:
    .byte $08

// move_counter slows the movement down.

move_counter:
    .byte 0

// setup_offsets defines the vertical distance of each bar from the base.
//
// These offsets are multiples of 8, so every generated setup line keeps the
// same phase.

setup_offsets:
    .byte 0                   // First bar offset
    .byte 8                   // Second bar offset
    .byte 16
    .byte 24
    .byte 32
    .byte 40
    .byte 48
    .byte 56
    .byte 64
    .byte $ff                 // Terminator

// setup_lines is generated from:
//
//   base_setup_line + setup_offsets
//
// The initial values here are only a readable starting state.
// The table is rebuilt at startup and after each completed stack.

setup_lines:
    .byte 92                  // setup 92, stable 93, target 94
    .byte 100                 // setup 100, stable 101, target 102
    .byte 108                 // setup 108, stable 109, target 110
    .byte 116                 // setup 116, stable 117, target 118
    .byte 124                 // setup 124, stable 125, target 126
    .byte 132                 // setup 132, stable 133, target 134
    .byte 140                 // setup 140, stable 141, target 142
    .byte 148                 // setup 148, stable 149, target 150
    .byte 156                 // setup 156, stable 157, target 158
    .byte $ff                 // Terminator

// bar_colours contains one colour per generated setup line.
//
// C64 colour values used here:
//
//   1  = white
//   3  = cyan
//   6  = blue
//   14 = light blue

bar_colours:
    .byte $06                 // blue
    .byte $06                 // blue
    .byte $0e                 // light blue
    .byte $03                 // cyan
    .byte $01                 // white
    .byte $03                 // cyan
    .byte $0e                 // light blue
    .byte $06                 // blue
    .byte $06                 // blue