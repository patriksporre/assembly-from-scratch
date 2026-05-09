# Lesson 03 - Memory map

## Goal

Introduce the first practical view of the Commodore 64 memory map.

The CPU sees addresses.

But not all addresses behave the same.

Some addresses behave like ordinary memory.

Some addresses are connected to hardware.

Some addresses control what appears on the screen.

In this lesson, we use the same basic instruction pattern several times:

```asm
lda #value
sta address
```

The instruction pattern is the same.

The address is different.

The result is different.

## What you will build

You will build a small C64 program that:

- Starts with `RUN`
- Changes the border colour
- Changes the background colour
- Writes a character to the top-left screen cell
- Sets the colour of that character
- Loops forever

The expected result is:

```text
Blue border
Black background
White A in the top-left corner
```

## What this teaches

This lesson teaches that the meaning of an address depends on where it is in the C64 memory map.

These four addresses all receive values from the CPU:

| Address | Meaning |
|---|---|
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |
| `$0400` | Default screen memory, top-left character cell |
| `$d800` | Colour RAM, colour for top-left character cell |

The same CPU instruction can write to all of them:

```asm
sta address
```

But the machine reacts differently depending on the address.

That is the first practical meaning of a memory map.

## Files

This lesson contains:

```text
platforms/c64/lessons/03-memory-map/
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
// Lesson 03: Memory map
//
// This lesson introduces the first practical view of the C64 memory map.
//
// The CPU can write to many addresses.
// Some addresses are ordinary memory.
// Some addresses are connected to hardware.
//
// In this lesson, we write to:
//
//   $d020 - VIC-II border colour register
//   $d021 - VIC-II background colour register
//   $0400 - screen memory, top-left character cell
//   $d800 - colour RAM, colour for top-left character cell
//
// Same instruction pattern.
// Different address.
// Different part of the machine responds.


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

    lda #$01                  // Load screen code $01 into the accumulator
    sta $0400                 // Store it in the top-left screen memory cell

    lda #$01                  // Load colour value $01 into the accumulator
    sta $d800                 // Store it in the colour RAM for the top-left cell

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

### Change the border colour

```asm
lda #$06
sta $d020
```

`lda #$06` loads colour value `$06` into the accumulator.

On the C64, colour value `$06` is blue.

`sta $d020` stores the accumulator into address `$d020`.

On the C64, `$d020` is the VIC-II border colour register.

So this changes the border colour to blue.

### Change the background colour

```asm
lda #$00
sta $d021
```

`lda #$00` loads colour value `$00` into the accumulator.

On the C64, colour value `$00` is black.

`sta $d021` stores the accumulator into address `$d021`.

On the C64, `$d021` is the VIC-II background colour register.

So this changes the background colour to black.

This is useful because the emulator may already show a blue background by default.

By writing to `$d021`, we make the background colour explicit.

### Write to screen memory

```asm
lda #$01
sta $0400
```

`$0400` is the start of the default C64 screen memory.

The first byte at `$0400` controls the top-left character cell.

The value `$01` is a C64 screen code.

For now, treat it as:

```text
$01 = A in screen memory
```

Important:

```text
This is not ASCII.
This is not PETSCII.
This is a C64 screen code.
```

Screen codes will be explained properly in the later text and character lesson.

For now, the important point is:

```text
Writing to $0400 changes the character shown in the top-left screen cell
```

### Write to colour RAM

```asm
lda #$01
sta $d800
```

`$d800` is the start of colour RAM.

The first byte at `$d800` controls the colour of the character cell at `$0400`.

The value `$01` is white.

So this makes the top-left character white.

This shows that, in the default character screen, the character and its colour are stored separately:

```text
$0400 = which character appears
$d800 = what colour that character has
```

### Infinite loop

```asm
loop:
    jmp loop
```

This keeps the program alive.

Without a loop or a clean return, the CPU would continue into whatever bytes happen to follow the program.

For this lesson, staying in an infinite loop is the safest behaviour.

## The key idea

The program uses the same pattern several times:

```asm
lda #value
sta address
```

But the meaning changes because the address changes.

```asm
sta $d020
```

changes the border colour.

```asm
sta $d021
```

changes the background colour.

```asm
sta $0400
```

changes the character in the top-left screen cell.

```asm
sta $d800
```

changes the colour of that character.

That is why the memory map matters.

The CPU is doing the same kind of work.

The machine responds differently because different addresses are connected to different things.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/03-memory-map
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
Blue border
Black background
White A in the top-left corner
```

## Machine concepts

This lesson introduces:

- The idea of a memory map
- Hardware registers
- Screen memory
- Colour RAM
- The difference between a character and its colour
- The idea that the same instruction can have different effects depending on the address

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- VIC-II colour registers

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

The new learning is not an instruction.

The new learning is the address map.

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
| `$0400` | Default screen memory, top-left character cell |
| `$d800` | Colour RAM, colour for top-left character cell |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the character

Change:

```asm
lda #$01
sta $0400
```

to:

```asm
lda #$02
sta $0400
```

Build and run again.

The top-left character should change.

Do not worry yet about the full screen-code table. That comes later.

### Change the character colour

Change:

```asm
lda #$01
sta $d800
```

to:

```asm
lda #$02
sta $d800
```

Build and run again.

The character colour should change.

### Change the background colour

Change:

```asm
lda #$00
sta $d021
```

to another colour value.

For example:

```asm
lda #$06
sta $d021
```

Build and run again.

The background should change.

### Move the character one cell to the right

Change:

```asm
sta $0400
```

to:

```asm
sta $0401
```

Then also change:

```asm
sta $d800
```

to:

```asm
sta $d801
```

Build and run again.

The character should move one cell to the right.

This shows that screen memory is laid out as consecutive character cells.

### Change the character but not the colour

Change only `$0400`.

Leave `$d800` unchanged.

This shows that character and colour are separate.

### Change the colour but not the character

Change only `$d800`.

Leave `$0400` unchanged.

This shows the same separation from the other direction.

## Common mistakes

### Thinking `$0400` and `$d800` are the same kind of memory

They are related, but they are not the same.

`$0400` controls which character is shown.

`$d800` controls the colour of that character.

### Expecting screen codes to be ASCII

The value stored in screen memory is a C64 screen code.

It is not ASCII.

It is not PETSCII.

This will be covered later.

### Forgetting to set the background colour

If you do not write to `$d021`, the background keeps whatever value it already had.

That may be the emulator's default background colour.

For a clear lesson, this program writes to `$d021` explicitly.

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
04 - Screen and display basics
```

Now that we have written one character to screen memory, we can slow down and understand the default C64 character screen more clearly.

The next lesson will focus on:

- Screen memory
- Character cells
- Rows and columns
- Screen codes
- How `$0400` maps to the visible screen
- How to place more than one character
- How to think about the C64 screen as memory
