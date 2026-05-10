# Lesson 06 - Bit operations and colour patterns

## Goal

Introduce a simple bit operation and use it to create a repeating colour pattern.

The new instruction is:

```asm
and #$0f
```

This keeps only the lower 4 bits of the accumulator.

That matters because the C64 has 16 colour values:

```text
$00 to $0f
```

16 values fit into 4 bits.

## What you will build

You will build a small C64 program that:

- Starts with `RUN`
- Sets the border and background colour
- Fills the first 256 screen cells with the letter `A`
- Gives each cell a colour based on the lower 4 bits of X
- Returns cleanly to BASIC with `rts`

The expected result is a block of `A` characters where the colour pattern repeats every 16 cells.

## What this teaches

This lesson builds directly on Lesson 05.

Lesson 05 introduced indexed addressing:

```asm
sta $0400,x
sta $d800,x
```

This lesson uses the same indexed addressing pattern, but adds one new idea:

```asm
and #$0f
```

The key learning is:

```text
X can walk through memory
The accumulator can be masked
The lower 4 bits can be used as a repeating colour value
```

The colour pattern repeats because:

```text
$00 & $0f = $00
$01 & $0f = $01
...
$0f & $0f = $0f
$10 & $0f = $00
$11 & $0f = $01
...
```

## Files

This lesson contains:

```text
platforms/c64/lessons/06-bit-operations-and-colour-patterns/
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
// Lesson 06: Bit operations and colour patterns
//
// This lesson introduces a simple bit operation.
//
// The C64 has 16 colour values:
//
//   $00 to $0f
//
// 16 values fit into 4 bits.
//
// This program fills the first 256 screen cells with the letter A.
// It then gives each cell a colour based on the lower 4 bits of X.
//
// The result is a repeating 16-colour pattern.

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
    lda #$06                  // Load colour value $06, blue
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    ldx #$00                  // Start X at zero

fill:
    lda letter_a              // Load the screen code stored at label letter_a
    sta $0400,x               // Store it at screen memory address $0400 + X

    txa                       // Transfer X to the accumulator
    and #$0f                  // Keep only the lower 4 bits ($00 to $0f)
    sta $d800,x               // Store the result as colour at $d800 + X

    inx                       // Move to the next position
    bne fill                  // Repeat until X wraps from $ff to $00

    rts                       // Return to BASIC

letter_a:
    .byte $01                 // Screen code $01, the letter A
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

### Set border and background colour

```asm
lda #$06
sta $d020
sta $d021
```

`lda #$06` loads colour value `$06` into the accumulator.

On the C64, colour value `$06` is blue.

`sta $d020` stores that value into the VIC-II border colour register.

`sta $d021` stores the same value into the VIC-II background colour register.

This is a small optimisation compared with loading the same colour twice.

It is safe because the accumulator still contains `$06` after the first `sta`.

The concept has already been learned, so the shorter form is now clearer.

### Start X at zero

```asm
ldx #$00
```

X is used as an offset into screen memory and colour RAM.

Starting X at zero means the first write uses the base addresses directly:

```text
$0400 + 0 = $0400
$d800 + 0 = $d800
```

### Fill label

```asm
fill:
```

`fill` is a label.

It marks the start of the repeated part of the program.

The program branches back to this label until X has gone through all 256 possible values.

### Load the character from data

```asm
lda letter_a
```

This loads the value stored at the label `letter_a` into the accumulator.

This is different from:

```asm
lda #$01
```

`lda #$01` loads the immediate value `$01`.

`lda letter_a` loads from memory at the address marked by `letter_a`.

In this program, `letter_a` contains one byte:

```asm
letter_a:
    .byte $01
```

So both approaches can load `$01`, but they teach different things.

Here, using a label prepares us for later lessons where data will live in named tables.

### Store the character using indexed addressing

```asm
sta $0400,x
```

This stores the accumulator at:

```text
$0400 + X
```

So as X changes, the program fills consecutive screen cells.

### Transfer X to the accumulator

```asm
txa
```

`txa` means:

```text
Transfer X to Accumulator
```

The next instruction, `and`, works on the accumulator.

So we first copy X into the accumulator.

### Mask the lower 4 bits

```asm
and #$0f
```

`and` performs a bitwise AND between the accumulator and the value provided.

`$0f` in binary is:

```text
00001111
```

This means:

```text
keep the lower 4 bits
clear the upper 4 bits
```

Examples:

| Value before `and #$0f` | Result |
|---|---|
| `$00` | `$00` |
| `$01` | `$01` |
| `$0f` | `$0f` |
| `$10` | `$00` |
| `$11` | `$01` |
| `$1f` | `$0f` |
| `$20` | `$00` |

This turns an increasing value into a repeating sequence from `$00` to `$0f`.

That sequence matches the 16 C64 colour values.

### Store the colour using indexed addressing

```asm
sta $d800,x
```

This stores the masked value at:

```text
$d800 + X
```

Colour RAM mirrors the screen memory position.

So the character written to `$0400 + X` gets its colour from `$d800 + X`.

### Increment X

```asm
inx
```

This increases X by one.

X is an 8-bit register, so it can hold values from:

```text
$00 to $ff
```

After `$ff`, it wraps to `$00`.

### Branch until X wraps

```asm
bne fill
```

`bne` means:

```text
Branch if Not Equal
```

Here, it uses the zero flag set by `inx`.

When X is incremented from `$ff` to `$00`, the result is zero.

At that point, `bne fill` does not branch.

So this loop runs exactly 256 times.

This is a compact and common 6502 loop pattern.

### Return to BASIC

```asm
rts
```

The program has filled the first 256 screen cells.

It does not need to keep running.

So it returns to BASIC.

The visible result remains because the characters and colours have already been written to screen memory and colour RAM.

### Character data

```asm
letter_a:
    .byte $01
```

This defines one byte of data.

The label `letter_a` marks where that byte lives.

The value `$01` is the C64 screen code for `A`.

This is the first small step toward separating code and data.

## The key idea

The program uses X in two different ways:

```text
X as a memory offset
X as the source of a colour pattern
```

First, X chooses where to write:

```asm
sta $0400,x
sta $d800,x
```

Then X is copied into the accumulator and masked:

```asm
txa
and #$0f
```

The mask keeps only values `$00` to `$0f`.

That gives us a repeating colour pattern.

## Why only 256 cells?

A full C64 screen has:

```text
40 columns * 25 rows = 1000 cells
```

This lesson fills only the first 256 cells.

That is intentional.

X is an 8-bit register.

It can count through 256 values:

```text
$00 to $ff
```

Filling all 1000 cells requires a different strategy.

That will be a later lesson.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/06-bit-operations-and-colour-patterns
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

You should see the first 256 screen cells filled with `A` characters.

The colours should repeat every 16 cells.

After the program runs, it returns to BASIC.

That is expected.

## Machine concepts

This lesson introduces:

- The C64's 16 colour values
- Colour values as 4-bit values
- Repeating colour patterns
- Filling the first 256 screen cells
- Separating small data from code with a label

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- Screen memory at `$0400`
- Colour RAM at `$d800`
- VIC-II border colour register at `$d020`
- VIC-II background colour register at `$d021`

## Assembly concepts

This lesson introduces:

- `and`
- Bit masking
- `txa`
- `bne` after `inx`
- Loading from a labelled memory location
- Defining data with `.byte`

It reuses:

- `lda`
- `ldx`
- `sta`
- `inx`
- Indexed addressing with X
- Labels
- Immediate values with `#`
- Hexadecimal values with `$`
- `rts`

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
| `$0400-$04ff` | First 256 screen memory cells filled by this lesson |
| `$d800-$d8ff` | Colour RAM for the first 256 screen cells |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the character

Change:

```asm
letter_a:
    .byte $01
```

to:

```asm
letter_a:
    .byte $02
```

Build and run again.

The filled character should change.

### Load the character directly

Replace:

```asm
lda letter_a
```

with:

```asm
lda #$01
```

Build and run again.

The visible result should be the same.

The difference is that one version loads from labelled data, and the other loads an immediate value.

### Change the mask

Change:

```asm
and #$0f
```

to:

```asm
and #$07
```

Build and run again.

The colour pattern should now repeat every 8 values instead of every 16.

### Remove the mask

Remove:

```asm
and #$0f
```

Build and run again.

Observe what happens to the colour pattern.

This experiment shows why the mask makes the 16-colour pattern explicit.

### Change the fill start address

Change:

```asm
sta $0400,x
sta $d800,x
```

to:

```asm
sta $0428,x
sta $d828,x
```

Build and run again.

The filled block should start on the second row.

## Common mistakes

### Thinking `and` means logical "and" in a sentence

In assembly, `and` is a bitwise operation.

It compares bits in the accumulator with bits in the value provided.

### Forgetting that `and` works on the accumulator

This is why the program does:

```asm
txa
and #$0f
```

`txa` copies X into the accumulator.

Then `and #$0f` masks the accumulator.

### Confusing `lda letter_a` and `lda #$01`

These both load `$01` in this program, but they do it differently.

```asm
lda #$01
```

loads the value `$01` directly.

```asm
lda letter_a
```

loads the value stored at the address marked by `letter_a`.

### Thinking this fills the whole screen

It does not.

It fills 256 cells.

The full screen has 1000 cells.

Handling that cleanly is a later lesson.

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
07 - Filling the screen
```

This lesson filled 256 cells because X is an 8-bit register.

The next natural problem is:

```text
How do we fill all 1000 screen cells?
```

That will introduce the need to handle memory in larger chunks or use a different addressing strategy.
