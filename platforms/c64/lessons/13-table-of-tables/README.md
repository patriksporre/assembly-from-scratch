# Lesson 13 - Table of tables

## Goal

Use a table of tables to drive multiple text tables.

Lesson 12 introduced a fixed table reader.

This lesson adds one more level of data-driven structure:

```text
table_list -> text table -> print routine -> screen
```

The program no longer directly chooses one text table in code.

Instead, it reads a list of table addresses.

Each table in that list is processed by the same text-table reader.

## What you will build

You will build a C64 program that prints:

```text
ASSEMBLY
FROM
SCRATCH


DATA DRIVES CODE
```

The first three lines come from one text table.

The final line comes from another text table.

Both tables use the same record format and the same reader.

## What this teaches

This lesson teaches:

- table of tables
- table pointers
- list pointers
- zero-word terminators
- fixed-size records that point to messages
- nested data-driven flow
- deliberate zero-page ownership
- using `ora` to check whether a 16-bit pointer is zero

The key structure is:

```text
table_list contains addresses of text tables
print_all_tables reads table_list
print_table reads each text table
print writes the final text
```

## Important zero-page note

Earlier lessons mostly used `$fb-$fe`, which are commonly available as zero-page workspace for small machine-code routines.

This lesson deliberately uses more zero-page locations:

| Pointer | Bytes used |
|---|---|
| `message_ptr` | `$fb-$fc` |
| `screen_ptr` | `$fd-$fe` |
| `colour_ptr` | `$02-$03` |
| `table_ptr` | `$04-$05` |
| `list_ptr` | `$06-$07` |

Some of these locations may normally be used by BASIC/KERNAL.

This is acceptable for this controlled lesson because we are moving toward machine-code ownership of the environment.

However, a fully BASIC-friendly program should be more careful with zero-page ownership.

The important principle is:

```text
Do not assume zero page is free.
Use it deliberately.
Document the trade-off.
```

## Fixed-size records

Each text record is 7 bytes:

```text
2 bytes - message address
2 bytes - screen address
2 bytes - colour RAM address
1 byte  - text colour
```

The message itself is not stored inline inside the record.

The record points to the message.

This keeps every record the same size, which makes the reader simpler.

Inline text records are possible, but they create variable-length records. That is a useful later topic, not part of this lesson.

## Files

This lesson contains:

```text
platforms/c64/lessons/13-table-of-tables/
├── README.md
├── main.asm
└── build.sh
```

Generated files such as `main.prg` are ignored by Git.

## Source code

The source code is in:

```text
main.asm
```

Current version:

```asm
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
```

## Code walkthrough

### BASIC loader

The BASIC loader is the same pattern introduced in Lesson 01b.

```asm
* = $0801

    .word basic_next_line
    .word 10
    .byte $9e
    .text "2061"
    .byte 0

basic_next_line:
    .word 0
```

This creates a tiny BASIC program:

```basic
10 SYS 2061
```

When you type:

```basic
RUN
```

BASIC starts the machine code at address `2061`.

Decimal `2061` is hexadecimal `$080d`.

### Zero-page pointers

```asm
.const message_ptr = $fb
.const screen_ptr  = $fd
.const colour_ptr  = $02
.const table_ptr   = $04
.const list_ptr    = $06
```

These constants name zero-page pointer locations.

The indirect indexed addressing mode:

```asm
(pointer),y
```

requires the pointer to live in zero page.

This lesson uses several pointers because there are several levels of data:

```text
list_ptr    -> table_list
table_ptr   -> current text table
message_ptr -> current message
screen_ptr  -> current screen destination
colour_ptr  -> current colour RAM destination
```

### Start routine

```asm
start:
    lda clear_colour
    sta $d020
    sta $d021

    jsr clear_screen

    lda #<table_list
    sta list_ptr
    lda #>table_list
    sta list_ptr + 1

    jsr print_all_tables

    rts
```

The start routine does four things:

```text
set display colour
clear the screen
point list_ptr at table_list
call print_all_tables
```

After all tables are processed, the program returns to BASIC.

### Table list

```asm
table_list:
    .word title_table
    .word footer_table
    .word 0
```

This table contains addresses of other tables.

It ends with:

```asm
.word 0
```

That is a zero-word terminator.

Because each table address is 16 bits, the terminator is also 16 bits.

### Reading the table list

```asm
print_all_tables:
    ldy #$00

next_table:
    lda (list_ptr),y
    sta table_ptr
    iny

    lda (list_ptr),y
    sta table_ptr + 1
    iny
```

This reads one table address from the table list.

The first byte is the low byte.

The second byte is the high byte.

Together they form a 16-bit address stored in `table_ptr`.

### Checking for a zero word

```asm
lda table_ptr
ora table_ptr + 1
beq tables_done
```

This checks whether the full 16-bit table address is zero.

A 16-bit pointer is zero only if both bytes are zero.

`ora` combines the low and high bytes.

Examples:

| Low byte | High byte | OR result | Meaning |
|---|---|---|---|
| `$00` | `$00` | `$00` | zero word, terminator |
| `$28` | `$04` | not zero | valid address |
| `$00` | `$08` | not zero | valid address |
| `$40` | `$00` | not zero | valid address |

So:

```asm
beq tables_done
```

means:

```text
if low byte OR high byte is zero, both bytes were zero, so the list is finished
```

This is a common way to test a 16-bit pointer for zero.

### Saving Y before calling print_table

```asm
tya
pha

jsr print_table

pla
tay
```

`Y` is the current offset into the table list.

`print_table` uses Y for its own table reading.

So `print_all_tables` saves Y before the call and restores it afterwards.

This follows the project convention:

```text
The caller saves what it needs.
```

### Print table routine

`print_table` reads records from the current text table.

Each record begins with a message address:

```asm
lda (table_ptr),y
sta message_ptr
iny

lda (table_ptr),y
sta message_ptr + 1
iny
```

Then it checks whether that message address is zero:

```asm
lda message_ptr
ora message_ptr + 1
beq records_done
```

If the message pointer is `$0000`, the text table is finished.

Otherwise, the routine continues reading the rest of the record.

### Reading one fixed-size record

After the message address, the record contains:

```text
screen address
colour RAM address
text colour
```

The routine reads each field in order and stores it in the inputs expected by `print`:

```text
message_ptr
screen_ptr
colour_ptr
text_colour
```

Then it calls:

```asm
jsr print
```

### Text tables

`title_table` contains three records:

```asm
title_table:
    .word message_assembly
    .word $0428
    .word $d828
    .byte $01

    .word message_from
    .word $0450
    .word $d850
    .byte $03

    .word message_scratch
    .word $0478
    .word $d878
    .byte $05

    .word 0
```

`footer_table` contains one record:

```asm
footer_table:
    .word message_data
    .word $04f0
    .word $d8f0
    .byte $07

    .word 0
```

Each table ends with a zero word.

### Why the messages are separate

The table records point to messages:

```asm
.word message_assembly
```

The messages themselves live elsewhere:

```asm
message_assembly:
    .text "ASSEMBLY"
    .byte 0
```

This keeps the table records fixed-size.

An alternative would be to store text inline inside the table, but then each record would have a different length. That requires a more advanced reader.

For this lesson, fixed-size records are the right choice.

## The key idea

Lesson 12 introduced:

```text
one table -> one reader
```

Lesson 13 introduces:

```text
table list -> many tables -> one reader per record format
```

The code is now driven by two levels of data:

```text
table_list chooses which tables to process
each text table chooses what text appears and where
```

This is a strong step toward data-driven demos and games.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/13-table-of-tables
```

Run:

```bash
./build.sh
```

The build script assembles the program and opens it in VICE:

```bash
#!/usr/bin/env bash
set -e

java -jar ../../tools/kickassembler/KickAss.jar main.asm
open -a x64sc main.prg
```

When the C64 screen appears, type:

```basic
RUN
```

You should see:

```text
ASSEMBLY
FROM
SCRATCH


DATA DRIVES CODE
```

with different colours.

## Machine concepts

This lesson introduces:

- deliberate broader zero-page use
- nested data-driven structures
- zero-word terminators
- table-of-tables structure
- fixed-size records pointing to separate message data

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- zero-page pointers
- screen memory
- colour RAM
- clear screen routine
- print routine
- stack preservation of Y
- zero-terminated text

## Assembly concepts

This lesson introduces or reinforces:

- `ora`
- checking a 16-bit pointer for zero
- `.word 0` as a zero-word terminator
- nested table readers
- using `(pointer),y` at multiple data levels
- caller-saves convention for Y
- fixed-size records containing pointers

It reuses:

- `lda`
- `sta`
- `ldy`
- `iny`
- `jmp`
- `jsr`
- `rts`
- `beq`
- `pha`
- `pla`
- `tay`
- `.word`
- `.byte`
- `.text`

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$fb-$fc` | `message_ptr` zero-page pointer |
| `$fd-$fe` | `screen_ptr` zero-page pointer |
| `$02-$03` | `colour_ptr` zero-page pointer |
| `$04-$05` | `table_ptr` zero-page pointer |
| `$06-$07` | `list_ptr` zero-page pointer |
| `$0400-$07ff` | Screen memory pages cleared by `clear_screen` |
| `$d800-$dbff` | Colour RAM pages initialised by `clear_screen` |
| `$0428`, `$0450`, `$0478`, `$04f0` | Screen positions used by tables |
| `$d828`, `$d850`, `$d878`, `$d8f0` | Colour RAM positions used by tables |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Add another table

Create a new table:

```asm
extra_table:
    .word message_extra
    .word $0518
    .word $d918
    .byte $0e

    .word 0

message_extra:
    .text "ANOTHER TABLE"
    .byte 0
```

Then add it to `table_list` before the zero terminator:

```asm
table_list:
    .word title_table
    .word footer_table
    .word extra_table
    .word 0
```

Build and run again.

### Remove a table from the list

Remove:

```asm
.word footer_table
```

from `table_list`.

Build and run again.

Only the title table should be processed.

### Break the table-list terminator

Remove:

```asm
.word 0
```

from `table_list`.

Build and run again.

The reader will continue reading whatever bytes follow as table addresses.

This is a useful mistake, but put the terminator back afterwards.

### Break a text-table terminator

Remove:

```asm
.word 0
```

from `footer_table`.

Build and run again.

The text-table reader will continue interpreting later data as text records.

Put the terminator back afterwards.

### Change a record colour

Change only one `.byte` colour value in a text table.

The reader and print routine do not change, but the visible colour does.

## Common mistakes

### Confusing zero byte and zero word

A zero-terminated message ends with:

```asm
.byte 0
```

A table of addresses ends with:

```asm
.word 0
```

Use a byte terminator for byte strings.

Use a word terminator for address lists.

### Forgetting that records are fixed-size

Each text record is seven bytes before the terminator.

If a field is missing, the reader loses alignment.

### Thinking `ora` adds the bytes

It does not add.

`ora` performs a bitwise OR.

Here, it is used only to check whether both bytes of a pointer are zero.

### Forgetting to save Y

Both table readers use Y.

Before one reader calls another routine that also uses Y, it saves Y on the stack.

### Assuming zero page is free

This lesson deliberately uses more zero-page locations.

That is a design choice.

It must be documented and understood.

## What comes next

Next lesson:

```text
14 - Inline text records
```

Now that fixed-size records are clear, the next natural step is to explore variable-length records, where text is stored directly inside the table.

That will require a reader that can walk through a record until it finds a zero byte, then continue with the next record.
