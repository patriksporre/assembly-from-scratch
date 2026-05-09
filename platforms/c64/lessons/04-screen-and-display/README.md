# Lesson 04 - Screen and display basics

## Goal

Understand the default Commodore 64 character screen as memory.

The C64 screen is a grid.

Memory is linear.

This lesson connects those two ideas.

## What you will build

You will build a small C64 program that:

- Starts with `RUN`
- Sets a blue border
- Sets a black background
- Writes the letter `A` at row 0, column 0
- Writes the letter `B` at row 0, column 1
- Writes the letter `C` at row 1, column 0
- Gives each letter its own colour
- Loops forever

The expected result is:

```text
AB
C
```

The letters appear in the top-left corner of the screen.

## What this teaches

This lesson teaches how the default C64 character screen maps to memory.

The key idea is:

```text
The screen is a 40-column grid, but the memory behind it is a sequence of bytes
```

In the default C64 setup:

```text
$0400 = row 0, column 0
$0401 = row 0, column 1
$0402 = row 0, column 2
```

The screen is 40 columns wide.

So the next row begins 40 bytes later:

```text
$0400 + 40 = $0428
```

That means:

```text
$0428 = row 1, column 0
```

Colour RAM follows the same position pattern, but starts at `$d800`:

```text
$d800 = colour for row 0, column 0
$d801 = colour for row 0, column 1
$d828 = colour for row 1, column 0
```

## Files

This lesson contains:

```text
platforms/c64/lessons/04-screen-and-display-basics/
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
// Lesson 04: Screen and display basics
//
// This lesson introduces the default C64 character screen.
//
// The screen is made of character cells.
// Each visible cell is controlled by one byte in screen memory.
//
// In the default C64 setup:
//
//   $0400 = row 0, column 0
//   $0401 = row 0, column 1
//   $0428 = row 1, column 0
//
// The screen is 40 columns wide.
//
// Colour is stored separately in colour RAM:
//
//   $d800 = colour for row 0, column 0
//   $d801 = colour for row 0, column 1
//   $d828 = colour for row 1, column 0
//
// The C64 screen is a grid, but memory is linear.

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
// Machine code
// -----------------------------------------------------------------------------

* = $080d

start:
    lda #$06                  // Load colour value $06 into the accumulator
    sta $d020                 // Store it in the VIC-II border colour register

    lda #$00                  // Load colour value $00 into the accumulator
    sta $d021                 // Store it in the VIC-II background colour register

    lda #$01                  // Load screen code $01, the letter A
    sta $0400                 // Store it at row 0, column 0

    lda #$01                  // Load colour value $01, white
    sta $d800                 // Store it as colour for row 0, column 0

    lda #$02                  // Load screen code $02, the letter B
    sta $0401                 // Store it at row 0, column 1

    lda #$02                  // Load colour value $02, red
    sta $d801                 // Store it as colour for row 0, column 1

    lda #$03                  // Load screen code $03, the letter C
    sta $0428                 // Store it at row 1, column 0

    lda #$05                  // Load colour value $05, green
    sta $d828                 // Store it as colour for row 1, column 0

loop:
    jmp loop                  // Stay here forever so the result remains visible
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

### Machine-code start

```asm
* = $080d
```

This tells KickAssembler to place the machine code at address `$080d`.

That must match the BASIC loader's `SYS 2061`.

### Set the border colour

```asm
lda #$06
sta $d020
```

`lda #$06` loads colour value `$06` into the accumulator.

On the C64, colour value `$06` is blue.

`sta $d020` stores the accumulator into address `$d020`.

On the C64, `$d020` is the VIC-II border colour register.

So this changes the border colour to blue.

### Set the background colour

```asm
lda #$00
sta $d021
```

`lda #$00` loads colour value `$00` into the accumulator.

On the C64, colour value `$00` is black.

`sta $d021` stores the accumulator into address `$d021`.

On the C64, `$d021` is the VIC-II background colour register.

So this changes the background colour to black.

### Write A at row 0, column 0

```asm
lda #$01
sta $0400
```

`$0400` is the start of default screen memory.

The byte at `$0400` controls the top-left character cell.

That position is:

```text
row 0, column 0
```

The value `$01` is the C64 screen code for `A`.

For now, treat it as a screen code, not ASCII and not PETSCII.

Screen codes will be explained more carefully in a later lesson.

### Set A's colour

```asm
lda #$01
sta $d800
```

`$d800` is the start of colour RAM.

The byte at `$d800` controls the colour of the character cell at `$0400`.

The value `$01` is white.

So the `A` becomes white.

### Write B at row 0, column 1

```asm
lda #$02
sta $0401
```

The next byte in screen memory controls the next visible character cell.

So:

```text
$0400 = row 0, column 0
$0401 = row 0, column 1
```

The value `$02` is the C64 screen code for `B`.

### Set B's colour

```asm
lda #$02
sta $d801
```

Colour RAM mirrors the same screen position pattern.

So:

```text
$d800 = colour for row 0, column 0
$d801 = colour for row 0, column 1
```

The value `$02` is red.

So the `B` becomes red.

### Write C at row 1, column 0

```asm
lda #$03
sta $0428
```

The screen is 40 columns wide.

That means the first character cell on the second row is 40 bytes after `$0400`:

```text
$0400 + 40 = $0428
```

So `$0428` means:

```text
row 1, column 0
```

The value `$03` is the C64 screen code for `C`.

### Set C's colour

```asm
lda #$05
sta $d828
```

Colour RAM uses the same position pattern as screen memory.

Since:

```text
$0400 + 40 = $0428
```

the matching colour RAM address is:

```text
$d800 + 40 = $d828
```

The value `$05` is green.

So the `C` becomes green.

### Infinite loop

```asm
loop:
    jmp loop
```

This keeps the program alive.

Without a loop or a clean return, the CPU would continue into whatever bytes happen to follow the program.

For this lesson, staying in an infinite loop is the safest behaviour.

## The key idea

The screen looks two-dimensional:

```text
row, column
```

But the memory is one-dimensional:

```text
byte, byte, byte, byte...
```

So we translate positions like this:

```text
screen address = screen memory start + row * 40 + column
```

For the default C64 screen:

```text
screen address = $0400 + row * 40 + column
```

The matching colour RAM address is:

```text
colour address = $d800 + row * 40 + column
```

For example:

| Position | Screen address | Colour RAM address |
|---|---|---|
| row 0, column 0 | `$0400` | `$d800` |
| row 0, column 1 | `$0401` | `$d801` |
| row 1, column 0 | `$0428` | `$d828` |
| row 1, column 1 | `$0429` | `$d829` |

This is the first step toward treating the C64 display as structured memory.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/04-screen-and-display-basics
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
A and B on the first row
C on the second row
Each letter has its own colour
```

## Machine concepts

This lesson introduces:

- The default C64 character screen
- Screen memory as a sequence of character cells
- The 40-column screen layout
- Colour RAM as a separate memory area
- Matching screen memory positions with colour RAM positions

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- VIC-II border colour register at `$d020`
- VIC-II background colour register at `$d021`

## Assembly concepts

This lesson reuses:

- `lda`
- `sta`
- `jmp`
- Labels
- Immediate values with `#`
- Hexadecimal values with `$`
- The accumulator
- Infinite loops

No new CPU instruction is introduced in this lesson.

The new learning is how screen positions map to memory addresses.

## Hardware registers used

| Address | Name | Purpose |
|---|---|---|
| `$d020` | VIC-II border colour register | Controls the border colour |
| `$d021` | VIC-II background colour register | Controls the background colour |

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$0400` | Screen memory, row 0, column 0 |
| `$0401` | Screen memory, row 0, column 1 |
| `$0428` | Screen memory, row 1, column 0 |
| `$d800` | Colour RAM for row 0, column 0 |
| `$d801` | Colour RAM for row 0, column 1 |
| `$d828` | Colour RAM for row 1, column 0 |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Move C one cell to the right

Change:

```asm
sta $0428
```

to:

```asm
sta $0429
```

Then change:

```asm
sta $d828
```

to:

```asm
sta $d829
```

Build and run again.

The `C` should move from row 1, column 0 to row 1, column 1.

This shows that the screen memory address and colour RAM address must move together.

### Move A down one row

Change:

```asm
sta $0400
```

to:

```asm
sta $0428
```

Then change:

```asm
sta $d800
```

to:

```asm
sta $d828
```

Build and run again.

The `A` should move down one row.

### Put three letters on the same row

Use:

```asm
sta $0400
sta $0401
sta $0402
```

for screen memory positions, with matching colour RAM addresses:

```asm
sta $d800
sta $d801
sta $d802
```

This places characters next to each other on the same row.

### Change only the colour RAM address

Move the colour address without moving the screen address.

For example, keep:

```asm
sta $0428
```

but change:

```asm
sta $d828
```

to:

```asm
sta $d829
```

The character and colour will no longer match the same screen cell.

This is a useful mistake.

It shows that screen memory and colour RAM are separate but positionally related.

### Change the screen code

Change:

```asm
lda #$01
```

before a screen memory write to another value.

For example:

```asm
lda #$04
```

Build and run again.

The visible character should change.

Do not worry yet about memorising screen codes. A later lesson will handle them more carefully.

## Common mistakes

### Forgetting that the screen is 40 columns wide

The next row does not begin at `$0410` or `$0420`.

It begins at:

```text
$0400 + 40 = $0428
```

### Moving the character but not the colour

If you move a character from `$0428` to `$0429`, also move its colour from `$d828` to `$d829`.

Otherwise, the colour no longer belongs to the same visible cell.

### Expecting screen codes to be ASCII

The values written to screen memory are C64 screen codes.

They are not ASCII.

They are not PETSCII.

This will be covered later.

### Forgetting to type RUN

The program uses the BASIC loader from Lesson 01b.

After opening `main.prg` in VICE, type:

```basic
RUN
```

### Committing generated files

Do not commit:

```text
main.prg
```

It is generated from `main.asm`.

The source file is what belongs in Git.

## What comes next

Next lesson:

```text
05 - Colour
```

We have now used colour RAM and VIC-II colour registers.

Next, we will slow down and focus on colour itself:

- C64 colour values
- Border colour
- Background colour
- Character colour
- Why colour RAM is separate
- What can and cannot be coloured independently
