# Lesson 12 - Tables and data-driven text

## Goal

Use a table of records to print multiple messages without repeating setup code.

This lesson introduces data-driven programming.

The key idea is:

```text
Data describes what should happen.
Code performs the mechanism.
```

In earlier lessons, we manually set up a message pointer, screen pointer, colour pointer, and text colour before calling `print`.

In this lesson, those values live in a table.

The program reads the table and uses each record to configure the print routine.

## What you will build

You will build a C64 program that prints:

```text
ASSEMBLY
FROM
SCRATCH
```

Each line is described by one table record.

Each line has:

```text
message address
screen address
colour RAM address
text colour
```

The visible output is familiar.

The internal structure is new.

## What this teaches

This lesson teaches:

- tables
- records
- data-driven behaviour
- fixed record formats
- table readers
- using data to configure subroutines
- saving a table offset across a subroutine call
- separating content data from mechanism code

The central flow is:

```text
data table -> table reader -> print routine -> screen
```

## Why this matters

This pattern is widely used in low-level programming.

On the C64 and other classic machines, data-driven programming appears in:

```text
text tables
sprite tables
animation tables
sine tables
colour sequences
raster timing tables
music data
level maps
demo timelines
```

Once the reader exists, changing the output often means changing data rather than rewriting code.

That is a major step toward demos, games, and structured programs.

## Files

This lesson contains:

```text
platforms/c64/lessons/12-tables-and-data-driven-text/
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
```

These constants name zero-page addresses used as two-byte pointers.

The print routine uses:

```asm
lda (message_ptr),y
sta (screen_ptr),y
sta (colour_ptr),y
```

The indirect indexed addressing mode requires the pointer to live in zero page.

### Start routine

```asm
start:
    lda clear_colour
    sta $d020
    sta $d021

    jsr clear_screen
```

The program starts by setting the border and background colour.

Then it clears the screen.

This gives the table-driven output a known display state.

### Record count

```asm
lda text_record_count
sta records_left
```

The program copies the number of table records into a runtime counter.

`text_record_count` is the source value.

`records_left` changes while the program runs.

This lets the table reader know how many records to process.

### Table offset

```asm
ldx #$00
```

X is used as the offset into `text_table`.

At the start:

```text
X = 0
```

That means the reader starts at the first byte of the first record.

### Reading one record

The reader loads seven bytes from the table.

The first two bytes form the message pointer:

```asm
lda text_table,x
sta message_ptr
inx

lda text_table,x
sta message_ptr + 1
inx
```

The next two bytes form the screen pointer:

```asm
lda text_table,x
sta screen_ptr
inx

lda text_table,x
sta screen_ptr + 1
inx
```

The next two bytes form the colour pointer:

```asm
lda text_table,x
sta colour_ptr
inx

lda text_table,x
sta colour_ptr + 1
inx
```

The final byte is the text colour:

```asm
lda text_table,x
sta text_colour
inx
```

After those seven bytes, X points to the next record.

### Saving the table offset

```asm
txa
pha

jsr print

pla
tax
```

X holds the current table offset.

The current version of `print` preserves X, but this lesson uses the project convention from Lesson 11:

```text
The caller saves what it needs.
```

The table reader needs X after the call.

So it saves X before calling `print`, then restores it afterwards.

This makes the reader robust even if `print` changes later.

### Processing the next record

```asm
dec records_left
bne next_record
```

After one record has been printed, the program decrements `records_left`.

If records remain, it loops back and reads the next record.

When no records remain, it returns to BASIC.

### Clear screen subroutine

`clear_screen` is the same structured display-preparation routine from earlier lessons.

It fills screen memory with spaces and initialises colour RAM.

Its contract is:

```text
Input:
  clear_colour

Output:
  screen memory filled with spaces
  colour RAM initialised

Destroys:
  A
  X
  flags

Preserves:
  Y

Memory used:
  $0400-$07ff
  $d800-$dbff
```

### Print subroutine

`print` prints one zero-terminated message using the pointers and colour set by the table reader.

Its contract is:

```text
Input:
  message_ptr
  screen_ptr
  colour_ptr
  text_colour

Output:
  message printed to screen memory
  matching colour RAM updated

Destroys:
  A
  Y
  flags

Preserves:
  X
```

### Table records

Each record is seven bytes:

```text
2 bytes - message address
2 bytes - screen address
2 bytes - colour RAM address
1 byte  - text colour
```

The table is:

```asm
text_table:
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
```

Because every record has the same shape, the reader can process one record after another.

### One reader per record format

This lesson has one reader for this record format.

That does not mean every table needs its own reader.

A better way to think is:

```text
one reader per record format
many tables can share that reader
```

Later, we can make the reader more reusable by passing a table pointer, but this lesson keeps the table fixed so the record structure is visible.

## The key idea

The table is content.

The reader is behaviour.

The print routine is mechanism.

Together:

```text
text_table describes the output
next_record reads one record
print performs the drawing
```

This is the first clear step from hard-coded setup code toward data-driven programs.

## Why the reader is intentionally explicit

The reader is not the most compact or efficient version possible.

That is intentional.

This version makes the record format visible:

```text
read byte
store byte
move to next byte
repeat
```

That is the right first version.

Later we can improve it with:

```text
table pointers
terminators instead of counts
macros for records
parallel tables
self-modifying code where speed matters
```

But not yet.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/12-tables-and-data-driven-text
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
```

with each line in a different colour.

## Machine concepts

This lesson introduces:

- data-driven programming
- tables
- records
- fixed record formats
- table readers
- table data as content
- code as interpreter of data

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- zero-page pointers
- screen memory
- colour RAM
- zero-terminated text
- C64 screen-code encoding
- clear screen routine
- print routine
- calling convention from Lesson 11

## Assembly concepts

This lesson introduces or reinforces:

- `.word` records
- `.byte` records
- table offsets with X
- runtime counters
- `dec`
- saving X with `txa` and `pha`
- restoring X with `pla` and `tax`
- caller-saves convention
- interpreting structured data byte by byte

It reuses:

- `lda`
- `sta`
- `ldx`
- `inx`
- `jsr`
- `rts`
- `bne`
- `beq`
- `(pointer),y`
- `.text`
- labels

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$fb-$fc` | `message_ptr` zero-page pointer |
| `$fd-$fe` | `screen_ptr` zero-page pointer |
| `$02-$03` | `colour_ptr` zero-page pointer |
| `$0400-$07ff` | Screen memory pages cleared by `clear_screen` |
| `$d800-$dbff` | Colour RAM pages initialised by `clear_screen` |
| `$0428`, `$0450`, `$0478` | Screen positions used by table records |
| `$d828`, `$d850`, `$d878` | Colour RAM positions used by table records |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Add a fourth record

Change:

```asm
text_record_count:
    .byte 3
```

to:

```asm
text_record_count:
    .byte 4
```

Then add a fourth table record and message.

For example:

```asm
    .word message_data
    .word $04a0
    .word $d8a0
    .byte $07

message_data:
    .text "DATA DRIVES CODE"
    .byte 0
```

Build and run again.

### Change only data

Change the screen address or colour in `text_table`.

Do not change the table reader.

Build and run again.

This shows that the output is now driven by data.

### Break the record format

Remove one `.word` from a record.

Build and run again.

The reader will interpret the wrong bytes as the wrong fields.

This shows why fixed record formats matter.

Put it back afterwards.

### Change record count incorrectly

Set:

```asm
text_record_count:
    .byte 2
```

Only two records should print.

Set it too high and the reader will continue into data that was not meant to be interpreted as table records.

This is a useful mistake.

### Change text colours

Change only the `.byte` colour values in `text_table`.

The print routine does not change, but the visible colours do.

## Common mistakes

### Thinking the CPU understands records

It does not.

A record is a structure we impose on bytes.

The reader must interpret the bytes in the same order they were written.

### Forgetting that `.word` is two bytes

Each `.word` writes a low byte and a high byte.

That is why each record contains:

```text
2 + 2 + 2 + 1 = 7 bytes
```

### Forgetting to update the record count

If you add a record, update `text_record_count`.

If the count is wrong, the reader processes too few or too many records.

### Forgetting to save X

X is the table offset.

If a called routine destroys X and the reader does not save it, the table reader loses its place.

This lesson saves X around `jsr print` deliberately.

### Expecting this to be the final efficient reader

It is not.

It is the first clear reader.

Efficiency and reusability come later.

## What comes next

Next lesson:

```text
13 - Reusable table reader
```

Now that the table concept is clear, the next improvement is to make the reader less tied to one table.

That will likely introduce a table pointer, so the same reader can process different tables with the same record format.
