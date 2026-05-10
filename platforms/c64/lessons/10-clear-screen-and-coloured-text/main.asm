// Assembly from Scratch
// Platform: Commodore 64
// Lesson 10: Clear screen and coloured text
//
// This lesson combines screen initialisation, subroutines, and coloured text.
//
// Lesson 09 introduced a reusable print routine using:
//
//   message_ptr - where the message starts
//   screen_ptr  - where the text should appear
//
// This lesson adds:
//
//   colour_ptr   - where the character colours should be written
//   clear_colour - colour used for the initial display state
//   text_colour  - colour used by the print routine
//   clear_screen - a subroutine that prepares the screen before drawing
//
// The program now has a simple structure:
//
//   initialise display
//   clear screen
//   print coloured text
//   return to BASIC
//
// The routine inputs are stored in named memory locations.
// This is simple and common on 6502-style machines, but it is shared state.
// Later lessons will introduce clearer calling conventions, register
// preservation, and stack use when those concepts have earned their place.

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

    lda #<message             // Load low byte of message address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message             // Load high byte of message address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0428               // Load low byte of screen address $0428
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0428               // Load high byte of screen address $0428
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    lda #<$d828               // Load low byte of colour RAM address $d828
    sta colour_ptr            // Store it in the low byte of colour_ptr
    lda #>$d828               // Load high byte of colour RAM address $d828
    sta colour_ptr + 1        // Store it in the high byte of colour_ptr

    lda #$01                  // Load colour value $01, white
    sta text_colour           // Store it as the current text colour

    jsr print                 // Print the message

    rts                       // Return to BASIC

// -----------------------------------------------------------------------------
// Clear screen subroutine
// -----------------------------------------------------------------------------
//
// Clears the visible character screen by filling screen memory with spaces.
//
// Input:
//
//   clear_colour - colour value used for border, background, and cleared cells
//
// Uses:
//
//   A - current value being written
//   X - offset into screen memory and colour RAM
//
// Destroys:
//
//   A
//   X
//
// This routine fills four 256-byte pages:
//
//   screen memory: $0400-$07ff
//   colour RAM:    $d800-$dbff
//
// The visible screen uses the first 1000 bytes.
// This routine fills 1024 bytes because that is simple and page-aligned.

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
// Uses:
//
//   A - current character or colour value
//   Y - offset into the message, screen position, and colour position
//
// Destroys:
//
//   A
//   Y

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
// Message and colour data
// -----------------------------------------------------------------------------

clear_colour:
    .byte $06                 // Colour used for border, background, and cleared cells

text_colour:
    .byte $01                 // Current text colour used by the print routine

message:
    .text "ASSEMBLY FROM SCRATCH"
    .byte 0