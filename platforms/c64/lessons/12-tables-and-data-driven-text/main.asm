// Assembly from Scratch
// Platform: Commodore 64
// Lesson 12: Tables and data-driven text
//
// This lesson introduces data-driven programming.
//
// Instead of manually setting up one message at a time,
// we describe the messages in a table.
//
// Each table record contains:
//
//   message address
//   screen address
//   colour RAM address
//   text colour
//
// The program reads each record, sets up the print routine,
// calls print, then moves to the next record.
//
// Data describes what should happen.
// Code performs the mechanism.
//
// The table reader in this lesson is intentionally explicit.
// Later lessons will make table readers more reusable and efficient.

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

    lda text_record_count     // Load the number of text records
    sta records_left          // Store it in records_left

    ldx #$00                  // Start X at the first byte of text_table

next_record:
    lda text_table,x          // Load message address low byte from table
    sta message_ptr           // Store it in message_ptr low byte
    inx                       // Move to next table byte

    lda text_table,x          // Load message address high byte from table
    sta message_ptr + 1       // Store it in message_ptr high byte
    inx                       // Move to next table byte

    lda text_table,x          // Load screen address low byte from table
    sta screen_ptr            // Store it in screen_ptr low byte
    inx                       // Move to next table byte

    lda text_table,x          // Load screen address high byte from table
    sta screen_ptr + 1        // Store it in screen_ptr high byte
    inx                       // Move to next table byte

    lda text_table,x          // Load colour RAM address low byte from table
    sta colour_ptr            // Store it in colour_ptr low byte
    inx                       // Move to next table byte

    lda text_table,x          // Load colour RAM address high byte from table
    sta colour_ptr + 1        // Store it in colour_ptr high byte
    inx                       // Move to next table byte

    lda text_table,x          // Load text colour from table
    sta text_colour           // Store it as the current text colour
    inx                       // Move to first byte of next record

    txa                       // Copy table offset X into A
    pha                       // Save table offset on the stack

    jsr print                 // Print the current record

    pla                       // Restore table offset into A
    tax                       // Put it back into X

    dec records_left          // One record has been printed
    bne next_record           // If records remain, process the next one

    rts                       // Return to BASIC

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
// Table data
// -----------------------------------------------------------------------------
//
// Each text table record is 7 bytes:
//
//   .word message address
//   .word screen address
//   .word colour RAM address
//   .byte text colour
//
// The code reads these records in order.
//
// This is one reader for this record format.
// Other tables with the same record format could use the same reader.

text_record_count:
    .byte 3                   // Number of records in text_table

records_left:
    .byte 0                   // Runtime counter used while reading text_table

text_table:
    .word message_assembly    // Message address
    .word $0428               // Screen address, row 1, column 0
    .word $d828               // Colour RAM address, row 1, column 0
    .byte $01                 // White

    .word message_from        // Message address
    .word $0450               // Screen address, row 2, column 0
    .word $d850               // Colour RAM address, row 2, column 0
    .byte $03                 // Cyan

    .word message_scratch     // Message address
    .word $0478               // Screen address, row 3, column 0
    .word $d878               // Colour RAM address, row 3, column 0
    .byte $05                 // Green

// -----------------------------------------------------------------------------
// Message and colour data
// -----------------------------------------------------------------------------

clear_colour:
    .byte $06                 // Colour used for border, background, and cleared cells

text_colour:
    .byte $01                 // Current text colour used by the print routine

message_assembly:
    .text "ASSEMBLY"
    .byte 0

message_from:
    .text "FROM"
    .byte 0

message_scratch:
    .text "SCRATCH"
    .byte 0