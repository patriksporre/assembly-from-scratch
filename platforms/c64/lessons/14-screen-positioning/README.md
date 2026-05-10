# Lesson 14 - Screen positioning

## Goal

Use row and column positions to place text on the C64 screen.

Earlier lessons placed text using raw screen addresses such as:

```text
$0428
$0450
$0478
```

These are real C64 screen memory addresses, but they do not immediately show where the text appears.

This lesson makes the screen layout explicit:

```text
screen address = $0400 + row * 40 + column
colour address = $d800 + row * 40 + column
```

The program no longer stores final screen and colour RAM addresses in the text table.

Instead, each record stores a row and column. The program calculates the final addresses before calling the print routine.

## What you will build

You will build a C64 program that prints:

```text
  ASSEMBLY
    FROM
      SCRATCH


          SCREEN POSITIONING
```

The exact placement is controlled by row and column values in a table.

Each table record contains:

```text
row
column
text colour
message address
```

The program converts the row and column into:

```text
screen_ptr
colour_ptr
```

Then it uses the existing print routine to write the message and colour data.

## What this teaches

This lesson teaches:

- the C64 text screen as a 40 x 25 grid
- how a row and column become a memory address
- why each screen row is 40 bytes wide
- why `$28` hexadecimal equals 40 decimal
- row address lookup tables
- low-byte and high-byte address tables
- 16-bit address addition using `clc` and `adc`
- using a table terminator instead of a record count
- preserving X when the caller needs it

The key structure is:

```text
row and column -> calculate_position -> print routine -> screen
```

## Important zero-page note

This lesson uses zero-page pointers:

| Pointer | Bytes used |
|---|---|
| `message_ptr` | `$fb-$fc` |
| `screen_ptr` | `$fd-$fe` |
| `colour_ptr` | `$02-$03` |

Earlier lessons mostly used `$fb-$fe`, which are commonly available as zero-page workspace for small machine-code routines.

This lesson also uses `$02-$03` for the colour pointer.

Some zero-page locations may normally be used by BASIC/KERNAL.

This is acceptable for this controlled lesson, but it must be understood as a deliberate choice.

The important principle remains:

```text
Do not assume zero page is free.
Use it deliberately.
Document the trade-off.
```

## Screen layout

The default C64 text screen is:

```text
40 columns wide
25 rows tall
```

Screen memory starts at:

```text
$0400
```

Colour RAM starts at:

```text
$d800
```

Each visible character cell has one byte in screen memory and one byte in colour RAM.

Screen memory decides which character appears.

Colour RAM decides the colour of that character.

Because each row is 40 bytes wide, row starts are spaced 40 bytes apart:

| Row | Screen address | Colour RAM address |
|---|---|---|
| 0 | `$0400` | `$d800` |
| 1 | `$0428` | `$d828` |
| 2 | `$0450` | `$d850` |
| 3 | `$0478` | `$d878` |

`$28` hexadecimal is 40 decimal.

So this:

```text
row 1, column 2
```

means:

```text
$0400 + 1 * 40 + 2 = $042a
```

The colour RAM address is calculated the same way:

```text
$d800 + 1 * 40 + 2 = $d82a
```

## Files

This lesson contains:

```text
platforms/c64/lessons/14-screen-positioning/
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
// Lesson 14: Screen positioning
//
// This lesson moves from raw screen addresses to row and column positions.
//
// Earlier lessons placed text using addresses such as:
//
//   $0428
//   $0450
//   $0478
//
// These addresses are real C64 screen memory addresses,
// but they do not immediately show where the text appears.
//
// The default C64 text screen is:
//
//   40 columns wide
//   25 rows tall
//
// Screen memory starts at $0400.
// Colour RAM starts at $d800.
//
// The address for a visible character position is:
//
//   screen address = $0400 + row * 40 + column
//   colour address = $d800 + row * 40 + column
//
// The 6510 CPU does not have a multiply instruction.
// Instead of calculating row * 40 directly,
// this lesson uses row address tables.
//
// Each table record contains:
//
//   row
//   column
//   text colour
//   message address
//
// The program converts row and column into screen and colour RAM pointers,
// then calls the existing print routine.

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

    ldx #$00                  // Start X at the first byte of text_table

next_record:
    lda text_table,x          // Load row from table
    cmp #$ff                  // $ff marks the end of the table
    beq table_done            // If row is $ff, all records are done

    sta row_value             // Store row for calculate_position
    inx                       // Move to next table byte

    lda text_table,x          // Load column from table
    sta column_value          // Store column for calculate_position
    inx                       // Move to next table byte

    lda text_table,x          // Load text colour from table
    sta text_colour           // Store it as the current text colour
    inx                       // Move to next table byte

    lda text_table,x          // Load message address low byte from table
    sta message_ptr           // Store it in message_ptr low byte
    inx                       // Move to next table byte

    lda text_table,x          // Load message address high byte from table
    sta message_ptr + 1       // Store it in message_ptr high byte
    inx                       // Move to first byte of next record

    txa                       // Copy table offset X into A
    pha                       // Save table offset on the stack

    jsr calculate_position    // Convert row and column into screen and colour pointers

    jsr print                 // Print the current record

    pla                       // Restore table offset into A
    tax                       // Put it back into X

    jmp next_record           // Process the next record

table_done:
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
// Table data
// -----------------------------------------------------------------------------
//
// Each text table record is 5 bytes:
//
//   .byte row
//   .byte column
//   .byte text colour
//   .word message address
//
// The code reads these records in order.
//
// The row and column are not hardware addresses.
// They are human screen positions.
//
// calculate_position converts them into:
//
//   screen_ptr
//   colour_ptr
//
// Valid C64 screen rows are 0-24.
// $ff is not a valid row, so we use it as the end marker.

text_table:
    .byte 1                   // Row 1
    .byte 2                   // Column 2
    .byte $01                 // White
    .word message_assembly    // Message address

    .byte 2                   // Row 2
    .byte 4                   // Column 4
    .byte $03                 // Cyan
    .word message_from        // Message address

    .byte 3                   // Row 3
    .byte 6                   // Column 6
    .byte $05                 // Green
    .word message_scratch     // Message address

    .byte 12                  // Row 12
    .byte 10                  // Column 10
    .byte $0e                 // Light blue
    .word message_positioning // Message address

    .byte $ff                 // End of table

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
    .byte 0                   // Current screen row used by calculate_position

column_value:
    .byte 0                   // Current screen column used by calculate_position

message_assembly:
    .text "ASSEMBLY"
    .byte 0

message_from:
    .text "FROM"
    .byte 0

message_scratch:
    .text "SCRATCH"
    .byte 0

message_positioning:
    .text "SCREEN POSITIONING"
    .byte 0
```

## Code walkthrough

### BASIC loader

The BASIC loader is the same pattern used in earlier lessons.

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

These constants name zero-page pointer locations.

The indirect indexed addressing mode:

```asm
(pointer),y
```

requires the pointer to live in zero page.

This lesson uses three pointers:

```text
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

    ldx #$00
```

The start routine does three things:

```text
set display colour
clear the screen
start reading text_table from offset zero
```

After that, execution continues into `next_record`.

### Text table

Each record in `text_table` describes one message:

```asm
.byte 1
.byte 2
.byte $01
.word message_assembly
```

This means:

```text
row 1
column 2
colour 1
message_assembly
```

The table is terminated by:

```asm
.byte $ff
```

Valid C64 rows are 0-24.

`$ff` is not a valid row, so it can safely mark the end of the table.

### Reading one record

The table reader uses X as the table offset.

```asm
ldx #$00
```

The first byte of each record is the row:

```asm
lda text_table,x
cmp #$ff
beq table_done
```

If the row is `$ff`, the table is finished.

Otherwise, the row is stored:

```asm
sta row_value
inx
```

Then the column is read:

```asm
lda text_table,x
sta column_value
inx
```

Then the text colour:

```asm
lda text_table,x
sta text_colour
inx
```

Then the message address:

```asm
lda text_table,x
sta message_ptr
inx

lda text_table,x
sta message_ptr + 1
inx
```

At this point, the inputs for `calculate_position` and `print` are prepared.

### Saving X before subroutine calls

```asm
txa
pha

jsr calculate_position
jsr print

pla
tax
```

X is the current offset into `text_table`.

The table reader needs X after the subroutine calls, so it saves X on the stack before calling them.

This follows the project convention:

```text
The caller saves what it needs.
```

Even if the current subroutines preserve X, the table reader protects its own state.

### Calculate position routine

`calculate_position` converts this:

```text
row_value
column_value
```

into this:

```text
screen_ptr
colour_ptr
```

First, it uses the row as an index into the row address tables:

```asm
ldy row_value

lda screen_row_low,y
sta screen_ptr

lda screen_row_high,y
sta screen_ptr + 1
```

Now `screen_ptr` points to the start of the selected screen row.

The same is done for colour RAM:

```asm
lda colour_row_low,y
sta colour_ptr

lda colour_row_high,y
sta colour_ptr + 1
```

Now `colour_ptr` points to the start of the selected colour RAM row.

### Adding the column

The column is then added to the row start address:

```asm
clc
lda screen_ptr
adc column_value
sta screen_ptr

lda screen_ptr + 1
adc #$00
sta screen_ptr + 1
```

`adc` means add with carry.

It does not only add:

```text
A + value
```

It adds:

```text
A + value + carry
```

So `clc` clears the carry flag before starting a fresh addition.

The low byte is updated first.

If the low byte crosses a page boundary, the carry flag is set.

Then the high byte uses:

```asm
adc #$00
```

This adds only the carry from the low-byte addition.

That is how the 6510 performs a 16-bit address addition.

The same process is repeated for `colour_ptr`.

### Row address tables

The 6510 does not have a multiply instruction.

So instead of calculating:

```text
row * 40
```

directly, this lesson uses lookup tables.

```asm
screen_row_low:
    .byte <($0400 +  0 * 40)
    .byte <($0400 +  1 * 40)
    .byte <($0400 +  2 * 40)

screen_row_high:
    .byte >($0400 +  0 * 40)
    .byte >($0400 +  1 * 40)
    .byte >($0400 +  2 * 40)
```

The low and high bytes are stored separately because the 6510 works naturally with one byte at a time.

The same pattern is used for colour RAM:

```asm
colour_row_low:
    .byte <($d800 +  0 * 40)

colour_row_high:
    .byte >($d800 +  0 * 40)
```

### Print routine

The print routine is the same mechanism used in earlier lessons.

```asm
lda (message_ptr),y
beq done

sta (screen_ptr),y

lda text_colour
sta (colour_ptr),y
```

It reads one byte from the message, writes it to screen memory, and writes the selected colour to colour RAM.

The print routine does not know anything about rows and columns.

It only receives final pointers:

```text
message_ptr
screen_ptr
colour_ptr
```

That separation is useful:

```text
calculate_position decides where
print writes the characters
```

## The key idea

Lesson 14 shifts the screen model from raw addresses to visible positions.

Earlier lessons used:

```text
screen address
colour RAM address
```

This lesson uses:

```text
row
column
```

and lets the program calculate the addresses.

That gives us a more natural way to think about the C64 screen:

```text
40 columns x 25 rows
```

This is still close to the hardware.

Rows and columns are not an abstraction that hides the machine. They are a clearer way to describe how screen memory is laid out.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/14-screen-positioning
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

You should see the messages printed at different row and column positions.

## Machine concepts

This lesson introduces:

- the C64 text screen as a 40 x 25 grid
- row and column positioning
- screen row start addresses
- colour RAM row start addresses
- the relationship between screen memory and visible positions
- `$28` hexadecimal as one 40-column row

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- VIC-II border colour register
- VIC-II background colour register
- screen memory
- colour RAM
- zero-page pointers
- clear screen routine
- print routine
- zero-terminated text

## Assembly concepts

This lesson introduces or reinforces:

- row address lookup tables
- low-byte and high-byte tables
- `clc`
- `adc`
- 16-bit address addition
- table terminator using `$ff`
- caller-saves convention for X
- using X as a table offset
- using Y as a table index

It reuses:

- `lda`
- `sta`
- `ldx`
- `ldy`
- `inx`
- `iny`
- `cmp`
- `beq`
- `jmp`
- `jsr`
- `rts`
- `pha`
- `pla`
- `tax`
- `txa`
- `.byte`
- `.word`
- `.text`
- `<` for low byte
- `>` for high byte

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
| `$0400` | Start of default screen memory |
| `$d800` | Start of colour RAM |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Move a message horizontally

Change the column for `message_assembly`:

```asm
.byte 1
.byte 2
```

Try:

```asm
.byte 1
.byte 10
```

Build and run again.

The message should move to the right.

### Move a message vertically

Change the row for `message_from`:

```asm
.byte 2
.byte 4
```

Try:

```asm
.byte 8
.byte 4
```

Build and run again.

The message should move down.

### Try the top-left corner

Add or change a record so it uses:

```asm
.byte 0
.byte 0
```

That means:

```text
row 0, column 0
```

The message should begin at the first visible character cell.

### Try the bottom row

Use row 24:

```asm
.byte 24
.byte 0
```

This is the last visible row of the default C64 text screen.

### Try column 39

Use column 39 with a short one-character message.

Column 39 is the last column on a row.

### Break the table terminator

Remove:

```asm
.byte $ff
```

Build and run again.

The table reader will continue reading whatever bytes follow as if they were more records.

This is a useful mistake, but put the terminator back afterwards.

### Use an invalid row

Try row 25 or higher.

The row address tables only contain rows 0-24, so the program will read the wrong row-table entry.

Put the row back to a valid value afterwards.

## Common mistakes

### Confusing row and column

The record format is:

```asm
.byte row
.byte column
.byte text colour
.word message address
```

Do not swap row and column unless you want the message to move to a different place.

### Forgetting that rows start at zero

The first row is row 0.

The last visible row is row 24.

There are 25 rows in total.

### Forgetting that columns start at zero

The first column is column 0.

The last column is column 39.

There are 40 columns in total.

### Forgetting the table terminator

The table must end with:

```asm
.byte $ff
```

Without it, the program continues reading later memory as more records.

### Using a row outside 0-24

The row tables only contain valid visible rows.

An invalid row reads from outside the intended table.

### Using a column outside 0-39

The program will still add the value to the row start address.

Column 40 is effectively the first character of the next row, but that is no longer a valid column for the current row.

### Forgetting `clc` before `adc`

`adc` means add with carry.

If carry is already set, the addition becomes one too high.

Use `clc` before starting a fresh addition.

### Losing the table offset in X

The table reader uses X as the offset into `text_table`.

Before calling subroutines, it saves X:

```asm
txa
pha
```

After the calls, it restores X:

```asm
pla
tax
```

This follows the project convention:

```text
The caller saves what it needs.
```

## What comes next

Next lesson:

```text
15 - Moving text
```

Now that text can be placed using row and column positions, the next natural step is to change those positions over time.

That brings us back toward visible machine behaviour:

```text
position
movement
animation
timing
```

This will lead toward raster timing, screen effects, and eventually more recognisable C64 demo techniques.
