// Assembly from Scratch
// Platform: Commodore 64
// Lesson 13: Table of tables
//
// This lesson extends the data-driven approach from Lesson 12.
//
// Lesson 12 used one fixed text table.
//
// This lesson adds:
//
//   table_list - a table containing addresses of other tables
//   table_ptr  - pointer to the current text table
//   list_ptr   - pointer to the table list
//
// Each text table contains fixed-size records.
// Each record describes one line of text.
//
// A zero word:
//
//   .word 0
//
// marks the end of a table.
//
// The result is a nested data-driven structure:
//
//   table_list -> text table -> print routine -> screen
//
// This lesson deliberately uses more zero-page locations than earlier lessons.
// That is a step toward taking more control of the machine.
//
// A fully BASIC-friendly program should be more careful with zero-page ownership.

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
// table_ptr uses $04-$05.
// list_ptr uses $06-$07.
//
// The indirect indexed addressing mode:
//
//   (pointer),y
//
// requires the pointer to live in zero page.
//
// Earlier lessons used mostly $fb-$fe because those bytes are commonly
// available as zero-page workspace.
//
// This lesson deliberately uses additional zero-page locations.
// Some of these locations may normally be used by BASIC/KERNAL.
//
// That is acceptable for this controlled machine-code lesson, but it means
// the program no longer tries to be perfectly polite to BASIC's zero-page state.

.const message_ptr = $fb
.const screen_ptr  = $fd
.const colour_ptr  = $02
.const table_ptr   = $04
.const list_ptr    = $06

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

    lda #<table_list          // Load low byte of table_list address
    sta list_ptr              // Store it in list_ptr low byte
    lda #>table_list          // Load high byte of table_list address
    sta list_ptr + 1          // Store it in list_ptr high byte

    jsr print_all_tables      // Process every table listed in table_list

    rts                       // Return to BASIC

// -----------------------------------------------------------------------------
// Print all tables subroutine
// -----------------------------------------------------------------------------
//
// Reads a list of table addresses from list_ptr.
//
// Each entry in the list is a 16-bit address:
//
//   .word title_table
//   .word footer_table
//   .word 0
//
// A zero word marks the end of the list.
//
// Input:
//
//   list_ptr - address of table list
//
// Output:
//
//   all tables in the list processed
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
//   table_ptr

print_all_tables:
    ldy #$00                  // Start Y at the first byte of the table list

next_table:
    lda (list_ptr),y          // Load table address low byte
    sta table_ptr             // Store it in table_ptr low byte
    iny                       // Move to table address high byte

    lda (list_ptr),y          // Load table address high byte
    sta table_ptr + 1         // Store it in table_ptr high byte
    iny                       // Move to next table-list entry

    lda table_ptr             // Check low byte of table address
    ora table_ptr + 1         // Combine with high byte
    beq tables_done           // If both bytes are zero, the list is finished

    tya                       // Save table-list offset Y
    pha                       // because print_table uses Y

    jsr print_table           // Process the current text table

    pla                       // Restore table-list offset into A
    tay                       // Put it back into Y

    jmp next_table            // Continue with next table in table_list

tables_done:
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Print table subroutine
// -----------------------------------------------------------------------------
//
// Reads text records from the table pointed to by table_ptr.
//
// Each text record is 7 bytes:
//
//   .word message address
//   .word screen address
//   .word colour RAM address
//   .byte text colour
//
// A zero message address:
//
//   .word 0
//
// marks the end of the text table.
//
// Input:
//
//   table_ptr - address of the text table to read
//
// Output:
//
//   all records in the table printed
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
//   message_ptr
//   screen_ptr
//   colour_ptr
//   text_colour

print_table:
    ldy #$00                  // Start Y at the first byte of the text table

next_record:
    lda (table_ptr),y         // Load message address low byte
    sta message_ptr           // Store it in message_ptr low byte
    iny                       // Move to message address high byte

    lda (table_ptr),y         // Load message address high byte
    sta message_ptr + 1       // Store it in message_ptr high byte
    iny                       // Move to screen address low byte

    lda message_ptr           // Check low byte of message address
    ora message_ptr + 1       // Combine with high byte
    beq records_done          // If both bytes are zero, the table is finished

    lda (table_ptr),y         // Load screen address low byte
    sta screen_ptr            // Store it in screen_ptr low byte
    iny                       // Move to screen address high byte

    lda (table_ptr),y         // Load screen address high byte
    sta screen_ptr + 1        // Store it in screen_ptr high byte
    iny                       // Move to colour RAM address low byte

    lda (table_ptr),y         // Load colour RAM address low byte
    sta colour_ptr            // Store it in colour_ptr low byte
    iny                       // Move to colour RAM address high byte

    lda (table_ptr),y         // Load colour RAM address high byte
    sta colour_ptr + 1        // Store it in colour_ptr high byte
    iny                       // Move to text colour byte

    lda (table_ptr),y         // Load text colour
    sta text_colour           // Store it as the current text colour
    iny                       // Move to first byte of next record

    tya                       // Save table offset Y
    pha                       // because print destroys Y

    jsr print                 // Print the current record

    pla                       // Restore table offset into A
    tay                       // Put it back into Y

    jmp next_record           // Continue with next text record

records_done:
    rts                       // Return to the caller

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
// Table list
// -----------------------------------------------------------------------------
//
// This table contains addresses of other tables.
//
// A zero word marks the end of the table list.

table_list:
    .word title_table         // Process title_table
    .word footer_table        // Process footer_table
    .word 0                   // End of table list

// -----------------------------------------------------------------------------
// Text tables
// -----------------------------------------------------------------------------
//
// Each text table contains fixed-size records.
//
// Each record is:
//
//   .word message address
//   .word screen address
//   .word colour RAM address
//   .byte text colour
//
// A zero word marks the end of each text table.

title_table:
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

    .word 0                   // End of title_table

footer_table:
    .word message_data        // Message address
    .word $04f0               // Screen address, row 6, column 0
    .word $d8f0               // Colour RAM address, row 6, column 0
    .byte $07                 // Yellow

    .word 0                   // End of footer_table

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

message_data:
    .text "DATA DRIVES CODE"
    .byte 0