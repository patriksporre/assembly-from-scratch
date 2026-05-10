// Assembly from Scratch
// Platform: Commodore 64
// Lesson 15: Moving text
//
// This lesson introduces simple movement.
//
// Lesson 14 converted row and column positions into screen and colour RAM
// addresses.
//
// This lesson changes the column value over time.
//
// The program:
//
//   calculates the current screen position
//   prints a message
//   waits for a short delay
//   erases the message
//   updates the column
//   repeats forever
//
// This is not yet synchronised to the raster beam.
// The delay loop is deliberately simple.
// Later lessons will introduce timing based on the C64 display hardware.

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
// Zero-page pointers
// -----------------------------------------------------------------------------
//
// These constants name zero-page addresses used as two-byte pointers.
//
// message_ptr uses $fb-$fc.
// screen_ptr uses $fd-$fe.
// colour_ptr uses $02-$03.
//
// The indirect indexed addressing mode:
//
//   (pointer),y
//
// requires the pointer to live in zero page.
//
// We use $fb-$fe because they are commonly available as zero-page workspace.
// We use $02-$03 for the third pointer in this controlled lesson.
// Do not assume that all zero page is free.

.const message_ptr = $fb
.const screen_ptr  = $fd
.const colour_ptr  = $02

// -----------------------------------------------------------------------------
// Machine code
// -----------------------------------------------------------------------------

* = $080d

.encoding "screencode_upper"  // Convert .text strings to C64 uppercase screen codes

start:
    lda clear_colour          // Load the colour used for the initial display state
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    jsr clear_screen          // Clear screen memory and initialise colour RAM

    lda #10                   // Start on row 10
    sta row_value             // Store current row

    lda #0                    // Start at column 0
    sta column_value          // Store current column

    lda #1                    // Start by moving right
    sta direction             // Store current direction

animation_loop:
    lda #<message_assembly    // Load low byte of message address
    sta message_ptr           // Store it in message_ptr low byte
    lda #>message_assembly    // Load high byte of message address
    sta message_ptr + 1       // Store it in message_ptr high byte

    lda #$01                  // White
    sta text_colour           // Store colour used by print

    jsr calculate_position    // Convert row and column into screen and colour pointers
    jsr print                 // Print the message at the current position

    jsr delay                 // Wait so the movement is visible

    lda #<message_spaces      // Load low byte of erase message address
    sta message_ptr           // Store it in message_ptr low byte
    lda #>message_spaces      // Load high byte of erase message address
    sta message_ptr + 1       // Store it in message_ptr high byte

    lda clear_colour          // Use the clear colour when erasing
    sta text_colour           // Store colour used by print

    jsr calculate_position    // Recalculate current position
    jsr print                 // Print spaces over the old message

    jsr update_position       // Move the column for the next frame

    jmp animation_loop        // Repeat forever

// -----------------------------------------------------------------------------
// Clear screen subroutine
// -----------------------------------------------------------------------------
//
// Input:
//
//   clear_colour - colour value used for border, background, and cleared cells
//
// Output:
//
//   screen memory filled with spaces
//   colour RAM initialised
//
// Destroys:
//
//   A
//   X
//   flags
//
// Preserves:
//
//   Y
//
// Memory used:
//
//   $0400-$07ff
//   $d800-$dbff

clear_screen:
    ldx #$00                  // Start X at zero

clear:
    lda #$20                  // Load screen code $20, space
    sta $0400,x               // Clear screen page $04
    sta $0500,x               // Clear screen page $05
    sta $0600,x               // Clear screen page $06
    sta $0700,x               // Clear screen page $07

    lda clear_colour          // Load colour used for cleared cells
    sta $d800,x               // Initialise colour RAM page $d8
    sta $d900,x               // Initialise colour RAM page $d9
    sta $da00,x               // Initialise colour RAM page $da
    sta $db00,x               // Initialise colour RAM page $db

    inx                       // Move to the next position
    bne clear                 // Repeat until X wraps from $ff to $00

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Calculate position subroutine
// -----------------------------------------------------------------------------
//
// Converts a row and column into screen memory and colour RAM pointers.
//
// Input:
//
//   row_value    - screen row, 0-24
//   column_value - screen column, 0-39
//
// Output:
//
//   screen_ptr - address of $0400 + row * 40 + column
//   colour_ptr - address of $d800 + row * 40 + column
//
// Destroys:
//
//   A
//   Y
//   flags
//
// Preserves:
//
//   X
//
// Memory used:
//
//   row_value
//   column_value
//   screen_ptr
//   colour_ptr

calculate_position:
    ldy row_value             // Use row as index into the row address tables

    lda screen_row_low,y      // Load low byte of screen row start address
    sta screen_ptr            // Store it in screen_ptr low byte

    lda screen_row_high,y     // Load high byte of screen row start address
    sta screen_ptr + 1        // Store it in screen_ptr high byte

    lda colour_row_low,y      // Load low byte of colour row start address
    sta colour_ptr            // Store it in colour_ptr low byte

    lda colour_row_high,y     // Load high byte of colour row start address
    sta colour_ptr + 1        // Store it in colour_ptr high byte

    clc                       // Clear carry before adding the column
    lda screen_ptr            // Load screen row start low byte
    adc column_value          // Add column offset within the row
    sta screen_ptr            // Store final screen address low byte

    lda screen_ptr + 1        // Load screen row start high byte
    adc #$00                  // Add carry if the low byte crossed a page boundary
    sta screen_ptr + 1        // Store final screen address high byte

    clc                       // Clear carry before adding the column again
    lda colour_ptr            // Load colour row start low byte
    adc column_value          // Add column offset within the row
    sta colour_ptr            // Store final colour address low byte

    lda colour_ptr + 1        // Load colour row start high byte
    adc #$00                  // Add carry if the low byte crossed a page boundary
    sta colour_ptr + 1        // Store final colour address high byte

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Print subroutine
// -----------------------------------------------------------------------------
//
// Prints a zero-terminated message to screen memory and colour RAM.
//
// Input:
//
//   message_ptr - address of the zero-terminated message
//   screen_ptr  - address where the message should appear
//   colour_ptr  - address where the character colours should be written
//   text_colour - colour value to use for the message
//
// Output:
//
//   message printed to screen memory
//   matching colour RAM updated
//
// Destroys:
//
//   A
//   Y
//   flags
//
// Preserves:
//
//   X

print:
    ldy #$00                  // Start Y at zero

copy:
    lda (message_ptr),y       // Load one byte from message_ptr + Y
    beq done                  // If the byte is zero, the message is finished

    sta (screen_ptr),y        // Store the byte at screen_ptr + Y

    lda text_colour           // Load the current text colour
    sta (colour_ptr),y        // Store it at colour_ptr + Y

    iny                       // Move to the next character
    jmp copy                  // Continue copying

done:
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Update position subroutine
// -----------------------------------------------------------------------------
//
// Updates the horizontal position of the moving message.
//
// Input:
//
//   column_value - current column
//   direction    - current direction
//
// Output:
//
//   column_value updated
//   direction changed when an edge is reached
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
//
// Memory used:
//
//   column_value
//   direction

update_position:
    lda direction             // Load current direction
    beq move_left             // Direction 0 means move left

move_right:
    inc column_value          // Move one column to the right

    lda column_value          // Load updated column
    cmp #32                   // Right edge for an 8-character word on a 40-column screen
    bne update_done           // If not at the edge, keep moving right

    lda #0                    // Change direction to left
    sta direction             // Store new direction

    jmp update_done           // Finish update

move_left:
    dec column_value          // Move one column to the left

    lda column_value          // Load updated column
    bne update_done           // If not at column 0, keep moving left

    lda #1                    // Change direction to right
    sta direction             // Store new direction

update_done:
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Delay subroutine
// -----------------------------------------------------------------------------
//
// Creates a simple visible delay.
//
// This is not hardware timing.
// It just burns CPU time in nested loops.
//
// Later lessons will replace this with timing based on the C64 raster beam.
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
//   X
//   Y
//   flags
//
// Preserves:
//
//   none

delay:
    ldx #$20                  // Outer delay counter

delay_outer:
    ldy #$ff                  // Inner delay counter

delay_inner:
    dey                       // Count down inner loop
    bne delay_inner           // Repeat until Y reaches zero

    dex                       // Count down outer loop
    bne delay_outer           // Repeat until X reaches zero

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Row address tables
// -----------------------------------------------------------------------------
//
// The C64 default screen is 40 columns wide.
//
// Row 0 starts at $0400.
// Row 1 starts at $0428.
// Row 2 starts at $0450.
//
// $28 hexadecimal is 40 decimal.
//
// The 6510 CPU does not have a multiply instruction,
// so instead of calculating row * 40 directly,
// we use tables with the start address of each row.
//
// The low and high bytes are stored separately because the 6510
// works naturally with one byte at a time.

screen_row_low:
    .byte <($0400 +  0 * 40)
    .byte <($0400 +  1 * 40)
    .byte <($0400 +  2 * 40)
    .byte <($0400 +  3 * 40)
    .byte <($0400 +  4 * 40)
    .byte <($0400 +  5 * 40)
    .byte <($0400 +  6 * 40)
    .byte <($0400 +  7 * 40)
    .byte <($0400 +  8 * 40)
    .byte <($0400 +  9 * 40)
    .byte <($0400 + 10 * 40)
    .byte <($0400 + 11 * 40)
    .byte <($0400 + 12 * 40)
    .byte <($0400 + 13 * 40)
    .byte <($0400 + 14 * 40)
    .byte <($0400 + 15 * 40)
    .byte <($0400 + 16 * 40)
    .byte <($0400 + 17 * 40)
    .byte <($0400 + 18 * 40)
    .byte <($0400 + 19 * 40)
    .byte <($0400 + 20 * 40)
    .byte <($0400 + 21 * 40)
    .byte <($0400 + 22 * 40)
    .byte <($0400 + 23 * 40)
    .byte <($0400 + 24 * 40)

screen_row_high:
    .byte >($0400 +  0 * 40)
    .byte >($0400 +  1 * 40)
    .byte >($0400 +  2 * 40)
    .byte >($0400 +  3 * 40)
    .byte >($0400 +  4 * 40)
    .byte >($0400 +  5 * 40)
    .byte >($0400 +  6 * 40)
    .byte >($0400 +  7 * 40)
    .byte >($0400 +  8 * 40)
    .byte >($0400 +  9 * 40)
    .byte >($0400 + 10 * 40)
    .byte >($0400 + 11 * 40)
    .byte >($0400 + 12 * 40)
    .byte >($0400 + 13 * 40)
    .byte >($0400 + 14 * 40)
    .byte >($0400 + 15 * 40)
    .byte >($0400 + 16 * 40)
    .byte >($0400 + 17 * 40)
    .byte >($0400 + 18 * 40)
    .byte >($0400 + 19 * 40)
    .byte >($0400 + 20 * 40)
    .byte >($0400 + 21 * 40)
    .byte >($0400 + 22 * 40)
    .byte >($0400 + 23 * 40)
    .byte >($0400 + 24 * 40)

colour_row_low:
    .byte <($d800 +  0 * 40)
    .byte <($d800 +  1 * 40)
    .byte <($d800 +  2 * 40)
    .byte <($d800 +  3 * 40)
    .byte <($d800 +  4 * 40)
    .byte <($d800 +  5 * 40)
    .byte <($d800 +  6 * 40)
    .byte <($d800 +  7 * 40)
    .byte <($d800 +  8 * 40)
    .byte <($d800 +  9 * 40)
    .byte <($d800 + 10 * 40)
    .byte <($d800 + 11 * 40)
    .byte <($d800 + 12 * 40)
    .byte <($d800 + 13 * 40)
    .byte <($d800 + 14 * 40)
    .byte <($d800 + 15 * 40)
    .byte <($d800 + 16 * 40)
    .byte <($d800 + 17 * 40)
    .byte <($d800 + 18 * 40)
    .byte <($d800 + 19 * 40)
    .byte <($d800 + 20 * 40)
    .byte <($d800 + 21 * 40)
    .byte <($d800 + 22 * 40)
    .byte <($d800 + 23 * 40)
    .byte <($d800 + 24 * 40)

colour_row_high:
    .byte >($d800 +  0 * 40)
    .byte >($d800 +  1 * 40)
    .byte >($d800 +  2 * 40)
    .byte >($d800 +  3 * 40)
    .byte >($d800 +  4 * 40)
    .byte >($d800 +  5 * 40)
    .byte >($d800 +  6 * 40)
    .byte >($d800 +  7 * 40)
    .byte >($d800 +  8 * 40)
    .byte >($d800 +  9 * 40)
    .byte >($d800 + 10 * 40)
    .byte >($d800 + 11 * 40)
    .byte >($d800 + 12 * 40)
    .byte >($d800 + 13 * 40)
    .byte >($d800 + 14 * 40)
    .byte >($d800 + 15 * 40)
    .byte >($d800 + 16 * 40)
    .byte >($d800 + 17 * 40)
    .byte >($d800 + 18 * 40)
    .byte >($d800 + 19 * 40)
    .byte >($d800 + 20 * 40)
    .byte >($d800 + 21 * 40)
    .byte >($d800 + 22 * 40)
    .byte >($d800 + 23 * 40)
    .byte >($d800 + 24 * 40)

// -----------------------------------------------------------------------------
// Message, colour, and position data
// -----------------------------------------------------------------------------

clear_colour:
    .byte $06                 // Colour used for border, background, and cleared cells

text_colour:
    .byte $01                 // Current text colour used by the print routine

row_value:
    .byte 0                   // Current screen row

column_value:
    .byte 0                   // Current screen column

direction:
    .byte 1                   // Current direction, 1 = right, 0 = left

message_assembly:
    .text "ASSEMBLY"
    .byte 0

message_spaces:
    .text "        "
    .byte 0