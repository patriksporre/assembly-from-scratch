# Lesson 15 - Moving text

## Goal

Move text across the C64 screen by changing its column position over time.

Lesson 14 introduced row and column positioning:

```text
row and column -> screen address
row and column -> colour RAM address
```

This lesson uses that idea to create simple movement.

The program repeatedly:

```text
calculates the current position
prints a message
waits
erases the message
updates the column
repeats
```

This is the first animation pattern in the C64 track.

## What you will build

You will build a C64 program that moves the word:

```text
ASSEMBLY
```

back and forth across one row of the screen.

The program does not use sprites yet.

It does not use raster timing yet.

It simply redraws text in different positions fast enough that we perceive movement.

## What this teaches

This lesson teaches:

- position as state
- horizontal movement
- erasing old output
- redrawing at a new position
- a simple animation loop
- using a delay loop to make movement visible
- using a direction value
- checking left and right movement bounds
- why screen updates need timing later

The key structure is:

```text
draw -> delay -> erase -> update -> repeat
```

This is a simple but important animation model.

## Important zero-page note

This lesson uses zero-page pointers:

| Pointer | Bytes used |
|---|---|
| `message_ptr` | `$fb-$fc` |
| `screen_ptr` | `$fd-$fe` |
| `colour_ptr` | `$02-$03` |

The indirect indexed addressing mode:

```asm
(pointer),y
```

requires the pointer to live in zero page.

`$fb-$fe` are commonly available as zero-page workspace for small machine-code routines.

`$02-$03` may normally be used by BASIC/KERNAL for some purposes. We use them here deliberately in a controlled machine-code lesson.

The important principle remains:

```text
Do not assume zero page is free.
Use it deliberately.
Document the trade-off.
```

## Animation model

The C64 does not automatically move text for us.

If a message appears at one position and we want it to appear somewhere else, we must manage the screen contents ourselves.

This lesson uses four steps:

```text
1. Print the message at the current position
2. Wait for a short time
3. Print spaces over the old message
4. Update the column position
```

Then the program repeats forever.

The erase message is:

```asm
message_spaces:
    .text "        "
    .byte 0
```

`ASSEMBLY` is 8 characters long.

So the erase message is 8 spaces long.

That means it covers the old word exactly.

## Movement bounds

The C64 screen has columns:

```text
0-39
```

The word:

```text
ASSEMBLY
```

is 8 characters long.

If it starts at column 32, it occupies:

```text
32, 33, 34, 35, 36, 37, 38, 39
```

That exactly fits the row.

If it starts at column 33, the last character would cross into the next row.

So the rightmost safe start column is:

```text
40 - 8 = 32
```

That is why the program checks:

```asm
cmp #32
```

The leftmost safe start column is:

```text
0
```

So when the column reaches 0, the program changes direction back to the right.

## Files

This lesson contains:

```text
platforms/c64/lessons/15-moving-text/
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

### Initial state

The program starts by setting the border and background colour:

```asm
lda clear_colour
sta $d020
sta $d021
```

Then it clears screen memory and colour RAM:

```asm
jsr clear_screen
```

Then it sets the initial movement state:

```asm
lda #10
sta row_value

lda #0
sta column_value

lda #1
sta direction
```

This means:

```text
start on row 10
start at column 0
start by moving right
```

### Animation loop

The main loop is:

```asm
animation_loop:
```

This loop never returns to BASIC.

It repeats forever.

The first part prepares the message:

```asm
lda #<message_assembly
sta message_ptr
lda #>message_assembly
sta message_ptr + 1

lda #$01
sta text_colour
```

Then it calculates the current screen position:

```asm
jsr calculate_position
```

and prints the message:

```asm
jsr print
```

Then it waits:

```asm
jsr delay
```

Then it prepares the erase message:

```asm
lda #<message_spaces
sta message_ptr
lda #>message_spaces
sta message_ptr + 1
```

and prints spaces over the previous word:

```asm
jsr calculate_position
jsr print
```

Finally, it updates the column:

```asm
jsr update_position
```

and repeats:

```asm
jmp animation_loop
```

### Why the message is erased

If the old word is not erased before the new word is drawn, the screen would fill with copies of the word.

The C64 screen memory keeps whatever bytes we write there.

Nothing disappears unless we overwrite it.

So movement requires two visible actions:

```text
draw the object
erase the old object
```

In this lesson, the object is text.

Later, the same basic thinking will apply to sprites, character graphics, and other effects, although the hardware mechanisms will differ.

### Update position routine

The movement state is stored in two bytes:

```asm
column_value:
    .byte 0

direction:
    .byte 1
```

`direction` means:

```text
1 = moving right
0 = moving left
```

The routine starts by checking the direction:

```asm
lda direction
beq move_left
```

If direction is zero, it branches to `move_left`.

Otherwise, it continues into `move_right`.

### Moving right

```asm
move_right:
    inc column_value
```

This moves the message one column to the right.

Then the program checks whether the right edge has been reached:

```asm
lda column_value
cmp #32
bne update_done
```

The rightmost safe start column is 32 because the screen is 40 columns wide and `ASSEMBLY` is 8 characters long.

```text
40 - 8 = 32
```

When the column reaches 32, the program changes direction:

```asm
lda #0
sta direction
```

### Moving left

```asm
move_left:
    dec column_value
```

This moves the message one column to the left.

Then the program checks whether it has reached column 0:

```asm
lda column_value
bne update_done
```

If the column is not zero, movement continues left.

If the column is zero, the program changes direction:

```asm
lda #1
sta direction
```

### Delay loop

The delay routine is:

```asm
delay:
    ldx #$20

delay_outer:
    ldy #$ff

delay_inner:
    dey
    bne delay_inner

    dex
    bne delay_outer

    rts
```

This burns CPU time.

It does not use the C64 display hardware.

It simply counts down in nested loops.

The larger the outer value, the slower the movement.

This is deliberately simple for now.

Later lessons will replace this with timing based on the raster beam.

### Calculate position routine

This routine is reused from Lesson 14.

It converts:

```text
row_value
column_value
```

into:

```text
screen_ptr
colour_ptr
```

It uses row address tables because the 6510 has no multiply instruction.

First, the row selects the start address of the row:

```asm
ldy row_value

lda screen_row_low,y
sta screen_ptr

lda screen_row_high,y
sta screen_ptr + 1
```

Then the column is added:

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

`clc` clears carry before starting a fresh addition.

The same calculation is repeated for colour RAM.

### Print routine

The print routine writes a zero-terminated message to screen memory and colour RAM:

```asm
lda (message_ptr),y
beq done

sta (screen_ptr),y

lda text_colour
sta (colour_ptr),y
```

It does not know whether it is drawing text or erasing text.

It simply copies whatever message `message_ptr` points to.

That is why the same print routine can write:

```text
ASSEMBLY
```

or:

```text
eight spaces
```

## The key idea

Lesson 15 introduces animation as repeated state change.

The state is:

```text
row_value
column_value
direction
```

Each frame uses the current state, draws the message, waits, erases it, and updates the state.

The visible movement is not a special C64 feature yet.

It is created by repeatedly changing memory.

That is a crucial foundation before we introduce hardware timing, raster waits, sprites, and more advanced effects.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/15-moving-text
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

You should see the word:

```text
ASSEMBLY
```

moving left and right across the screen.

## Machine concepts

This lesson introduces:

- movement through repeated screen updates
- screen memory as persistent visible state
- erasing by overwriting with spaces
- simple animation without hardware timing
- the need for better timing later

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- VIC-II border colour register
- VIC-II background colour register
- screen memory
- colour RAM
- zero-page pointers
- row and column positioning
- row address tables
- clear screen routine
- print routine
- zero-terminated text

## Assembly concepts

This lesson introduces or reinforces:

- infinite animation loop
- `inc`
- `dec`
- direction as a state byte
- bounds checking with `cmp`
- simple delay loops
- nested loops
- using X and Y as counters
- redrawing and erasing through the same print routine

It reuses:

- `lda`
- `sta`
- `ldx`
- `ldy`
- `bne`
- `beq`
- `jmp`
- `jsr`
- `rts`
- `clc`
- `adc`
- `.byte`
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

### Change the row

Change:

```asm
lda #10
sta row_value
```

Try another row, for example:

```asm
lda #5
sta row_value
```

Build and run again.

The word should move on a different row.

### Change the starting column

Change:

```asm
lda #0
sta column_value
```

Try:

```asm
lda #12
sta column_value
```

Build and run again.

The word should start closer to the middle of the screen.

### Change the direction

Change:

```asm
lda #1
sta direction
```

to:

```asm
lda #0
sta direction
```

Build and run again.

The word now starts by moving left.

If the starting column is still 0, think about what happens and why.

### Change the speed

In the delay routine, change:

```asm
ldx #$20
```

Try:

```asm
ldx #$10
```

or:

```asm
ldx #$40
```

Build and run again.

A smaller value should move faster.

A larger value should move slower.

### Change the message

Change:

```asm
message_assembly:
    .text "ASSEMBLY"
    .byte 0
```

to another 8-character word.

If you choose a different length, also update:

```asm
message_spaces:
    .text "        "
    .byte 0
```

and the right-edge check:

```asm
cmp #32
```

### Break the erase message

Shorten `message_spaces`.

Build and run again.

You should see leftover characters because the old message is not fully erased.

Put the correct number of spaces back afterwards.

### Break the right edge

Change:

```asm
cmp #32
```

to:

```asm
cmp #39
```

Build and run again.

Observe what happens when the message reaches the right side of the row.

Put the safe value back afterwards.

## Common mistakes

### Forgetting that screen memory persists

Characters remain on screen until something overwrites them.

Moving text means writing new characters and erasing old ones.

### Erasing with too few spaces

The erase message must be the same length as the visible message.

If it is too short, old characters remain on screen.

### Using the wrong right-edge value

For an 8-character message on a 40-column screen, the rightmost start column is:

```text
40 - 8 = 32
```

If the message length changes, this value must change too.

### Starting left while already at column 0

If `direction` is 0 and `column_value` is 0, the program will decrement from 0 to 255.

That is because an 8-bit value wraps around.

This is a useful mistake to observe, but not the intended movement.

### Thinking the delay loop is proper timing

The delay loop only burns CPU time.

It is not synchronised to the C64 display.

The speed depends on how long the CPU spends in the loop.

Later lessons will use the raster beam to make timing more meaningful.

### Forgetting that this is not a sprite

This lesson moves text by rewriting screen memory.

Sprites are a separate C64 hardware feature.

We will get there later.

## What comes next

Next lesson:

```text
16 - Raster beam basics
```

Now that we have movement, we need to understand timing.

The current program moves because of a simple CPU delay loop.

The next step is to look at the C64 display itself:

```text
raster beam
scanlines
frames
waiting for a screen position
```

That will prepare us for smoother animation, raster colour effects, and later interrupt-driven routines.
