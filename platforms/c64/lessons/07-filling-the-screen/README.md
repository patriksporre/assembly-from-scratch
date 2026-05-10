# Lesson 07 - Filling the screen

## Goal

Fill the full Commodore 64 character screen.

In Lesson 06, we filled 256 screen cells because X is an 8-bit register.

This lesson asks the next practical question:

```text
How do we fill a 1000-cell screen when X can only count 256 positions?
```

The answer in this lesson is simple and explicit:

```text
Use the same X offset across four 256-byte pages.
```

## What you will build

You will build a small C64 program that:

- Starts with `RUN`
- Sets the border and background colour
- Fills the visible character screen with the letter `A`
- Fills the matching colour RAM with a repeating colour pattern
- Returns cleanly to BASIC with `rts`

The expected result is a full screen of `A` characters with colours repeating in a pattern.

## What this teaches

This lesson teaches how to use indexed addressing across several memory pages.

In Lesson 06, this filled 256 cells:

```asm
sta $0400,x
```

This lesson extends the idea:

```asm
sta $0400,x
sta $0500,x
sta $0600,x
sta $0700,x
```

The X register is still only 8-bit.

But each instruction has a different 16-bit base address.

So the same X value writes to four different pages.

The key idea is:

```text
Same X.
Different pages.
Four blocks filled in parallel.
```

## Why pages matter

The 6510 CPU has a 16-bit address space:

```text
$0000 to $ffff
```

But the CPU registers A, X, and Y are 8-bit registers.

X can hold:

```text
$00 to $ff
```

That gives 256 possible offsets.

When we write:

```asm
sta $0400,x
```

the base address is 16-bit:

```text
$0400
```

and X is added as an 8-bit offset:

```text
$0400 + X
```

So this instruction can reach:

```text
$0400-$04ff
```

That is one 256-byte page.

To fill more than one page, this lesson repeats the store with different base addresses.

## Files

This lesson contains:

```text
platforms/c64/lessons/07-filling-the-screen/
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
// Lesson 07: Filling the screen
//
// This lesson fills the full C64 character screen.
//
// A C64 text screen has:
//
//   40 columns * 25 rows = 1000 cells
//
// In the previous lesson, we filled 256 cells using X as an 8-bit offset.
//
// X can count from:
//
//   $00 to $ff
//
// That gives us 256 positions.
//
// To cover the full screen, this lesson fills four 256-byte pages:
//
//   $0400-$04ff
//   $0500-$05ff
//   $0600-$06ff
//   $0700-$07ff
//
// This covers 1024 bytes.
// The visible screen uses the first 1000 of those bytes.

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
    sta $0400,x               // Fill screen page $04
    sta $0500,x               // Fill screen page $05
    sta $0600,x               // Fill screen page $06
    sta $0700,x               // Fill screen page $07

    txa                       // Transfer X to the accumulator
    and #$0f                  // Keep only the lower 4 bits ($00 to $0f)
    sta $d800,x               // Fill colour RAM page $d8
    sta $d900,x               // Fill colour RAM page $d9
    sta $da00,x               // Fill colour RAM page $da
    sta $db00,x               // Fill colour RAM page $db

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

We use the shorter form because the accumulator still contains `$06` after the first `sta`.

### Start X at zero

```asm
ldx #$00
```

X is used as an offset into each 256-byte page.

Starting X at zero means the first pass through the loop writes to:

```text
$0400
$0500
$0600
$0700
```

and the matching colour RAM addresses:

```text
$d800
$d900
$da00
$db00
```

### Fill label

```asm
fill:
```

`fill` marks the start of the repeated part of the program.

The loop runs until X has gone through all 256 values.

### Load the character

```asm
lda letter_a
```

This loads the value stored at the label `letter_a`.

The data is defined at the end of the program:

```asm
letter_a:
    .byte $01
```

`$01` is the C64 screen code for `A`.

### Fill four screen pages

```asm
sta $0400,x
sta $0500,x
sta $0600,x
sta $0700,x
```

These four stores use the same accumulator value and the same X offset.

But each store has a different base address.

When X is `$00`, the stores go to:

```text
$0400
$0500
$0600
$0700
```

When X is `$01`, the stores go to:

```text
$0401
$0501
$0601
$0701
```

When X is `$ff`, the stores go to:

```text
$04ff
$05ff
$06ff
$07ff
```

So the loop fills:

```text
$0400-$04ff
$0500-$05ff
$0600-$06ff
$0700-$07ff
```

That is 1024 bytes.

### Create the colour value

```asm
txa
and #$0f
```

`txa` copies X into the accumulator.

`and #$0f` keeps only the lower 4 bits.

That creates a repeating value from `$00` to `$0f`.

This matches the 16 C64 colour values.

### Fill four colour RAM pages

```asm
sta $d800,x
sta $d900,x
sta $da00,x
sta $db00,x
```

These stores mirror the screen memory stores.

They fill colour RAM pages:

```text
$d800-$d8ff
$d900-$d9ff
$da00-$daff
$db00-$dbff
```

This gives the filled screen a repeating colour pattern.

### Increment X

```asm
inx
```

This increases X by one.

X is an 8-bit register.

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

When X wraps from `$ff` to `$00`, the result is zero.

At that point, `bne fill` does not branch, and the loop ends.

This means the loop runs 256 times.

### Return to BASIC

```asm
rts
```

The program has finished writing to screen memory and colour RAM.

It does not need to keep running.

So it returns to BASIC.

The visible result remains because the screen memory and colour RAM have already been changed.

## Why this fills slightly more than the visible screen

The visible C64 character screen has:

```text
40 columns * 25 rows = 1000 cells
```

The default visible screen memory range is:

```text
$0400-$07e7
```

But this lesson fills:

```text
$0400-$07ff
```

That is 1024 bytes.

So the last 24 bytes:

```text
$07e8-$07ff
```

are beyond the visible 1000 screen cells in the default character screen.

This is acceptable for this lesson because the goal is to understand pages and indexed addressing.

The method is:

```text
simple, explicit, and slightly broad
```

A later lesson can make the fill exact.

## The key idea

The CPU can address 64 KB:

```text
$0000-$ffff
```

But X can only offset 256 positions:

```text
$00-$ff
```

So this lesson fills the screen by repeating the same indexed store across several 256-byte pages:

```asm
sta $0400,x
sta $0500,x
sta $0600,x
sta $0700,x
```

That is the important pattern.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/07-filling-the-screen
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

You should see the screen filled with `A` characters and a repeating colour pattern.

After the program runs, it returns to BASIC.

That is expected.

## Machine concepts

This lesson introduces:

- Filling the full visible character screen
- 256-byte memory pages
- The screen memory range `$0400-$07e7`
- The practical difference between 1000 visible cells and 1024 bytes filled
- Using several 16-bit base addresses with the same 8-bit X offset

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- Screen memory at `$0400`
- Colour RAM at `$d800`
- VIC-II border colour register at `$d020`
- VIC-II background colour register at `$d021`

## Assembly concepts

This lesson reuses:

- `lda`
- `ldx`
- `sta`
- `txa`
- `and`
- `inx`
- `bne`
- `rts`
- Indexed addressing with X
- Labels
- Defining data with `.byte`

The new learning is not a new instruction.

The new learning is how the same indexed addressing pattern can cover multiple pages.

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
| `$0400-$07ff` | Four screen-memory pages filled by this lesson |
| `$d800-$dbff` | Four colour RAM pages filled by this lesson |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the filled character

Change:

```asm
letter_a:
    .byte $01
```

to another screen code.

For example:

```asm
letter_a:
    .byte $02
```

Build and run again.

The screen should fill with a different character.

### Fill fewer pages

Remove these two stores:

```asm
sta $0600,x
sta $0700,x
```

and the matching colour RAM stores:

```asm
sta $da00,x
sta $db00,x
```

Build and run again.

Only part of the screen should be filled.

### Change the colour pattern

Change:

```asm
and #$0f
```

to:

```asm
and #$07
```

Build and run again.

The colour pattern should repeat every 8 values instead of every 16.

### Use one colour for the whole screen

Replace:

```asm
txa
and #$0f
```

with:

```asm
lda #$01
```

Build and run again.

The whole screen should use one character colour.

### Make the background black

Change:

```asm
sta $d020
sta $d021
```

to:

```asm
sta $d020

lda #$00
sta $d021
```

Build and run again.

The border remains blue, but the background becomes black.

## Common mistakes

### Thinking X is 16-bit

X is not 16-bit.

X is 8-bit.

It can hold `$00-$ff`.

The full address is 16-bit because the instruction contains a 16-bit base address, such as `$0400`.

### Calling pages "segments"

Use "pages" for this project.

A page is a 256-byte address range such as:

```text
$0400-$04ff
```

The word "segment" can mean something specific on other machines, especially DOS/x86.

### Thinking this is the only way to fill the screen

It is not.

This is the simplest method introduced so far.

Later we will learn more flexible approaches, such as pointer-based addressing.

### Forgetting that this fills 1024 bytes

The visible screen is 1000 cells.

This program fills 1024 bytes.

The extra 24 bytes are beyond the visible default screen area.

That is acceptable here, but important to understand.

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
08 - Text and character output
```

We can now fill screen memory and colour RAM.

Next, we should make text output more intentional:

- screen codes
- character sequences
- placing text at chosen positions
- using data tables
- copying text until an end marker
- eventually clearing and moving text

This moves us from filling memory to writing meaningful text.
