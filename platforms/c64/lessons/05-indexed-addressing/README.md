# Lesson 05 - Indexed addressing

## Goal

Use the X register as an offset into memory.

In earlier lessons, we wrote to fixed screen addresses:

```asm
sta $0400
sta $0401
sta $0402
```

That works, but it does not scale.

Indexed addressing lets the CPU calculate the target address by adding a register value to a base address:

```asm
sta $0400,x
```

This means:

```text
store at $0400 + X
```

So:

```text
X = $00 -> write to $0400
X = $01 -> write to $0401
X = $02 -> write to $0402
```

This is the first step toward walking through memory with a loop.

## What you will build

You will build a small C64 program that:

- Starts with `RUN`
- Sets a blue border
- Sets a black background
- Writes the letters `A` to `P` across the top row
- Gives each letter the same colour
- Uses X as a screen and colour RAM offset
- Uses Y as the current character value
- Returns cleanly to BASIC with `rts`

The expected result is:

```text
ABCDEFGHIJKLMNOP
```

in white on the top row.

## What this teaches

This lesson teaches three important ideas:

```text
X can be used as an offset into memory
Y can hold a changing character value
A carries values into memory
```

The core data flow is:

```text
Y -> accumulator -> screen memory
```

The core memory addressing pattern is:

```text
base address + X
```

The core loop is:

```text
copy character
set colour
increase X
increase Y
compare X with 16
repeat until done
```

## Files

This lesson contains:

```text
platforms/c64/lessons/05-indexed-addressing/
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
// Lesson 05: Indexed addressing
//
// This lesson introduces indexed addressing.
//
// In earlier lessons, we wrote to fixed screen addresses:
//
//   sta $0400
//   sta $0401
//   sta $0402
//
// Indexed addressing lets the X register act as an offset:
//
//   sta $0400,x
//
// This means:
//
//   store at $0400 + X
//
// If X is $00, the address is $0400.
// If X is $01, the address is $0401.
// If X is $02, the address is $0402.
//
// This lets us walk through memory with a loop.

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
    ldy #$01                  // Start Y at one (A = $01)

copy:
    tya                       // Transfer Y to the accumulator
    sta $0400,x               // Store it at screen memory address $0400 + X

    lda #$01                  // Load colour value $01, white
    sta $d800,x               // Store it at colour RAM address $d800 + X

    inx                       // Move to the next screen position
    iny                       // Move to the next character
    cpx #$10                  // Have we copied 16 characters?
    bne copy                  // If X is not 16, keep copying

    rts                       // Return to BASIC
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

`sta $d020` stores the accumulator into the VIC-II border colour register.

So this changes the border colour to blue.

### Set the background colour

```asm
lda #$00
sta $d021
```

`lda #$00` loads colour value `$00` into the accumulator.

On the C64, colour value `$00` is black.

`sta $d021` stores the accumulator into the VIC-II background colour register.

So this changes the background colour to black.

### Start X at zero

```asm
ldx #$00
```

`ldx` means:

```text
LoaD X register
```

The X register is an 8-bit register inside the 6510 CPU.

In this lesson, X is used as an offset into screen memory and colour RAM.

Starting X at zero means the first write uses the base address exactly:

```text
$0400 + 0 = $0400
$d800 + 0 = $d800
```

### Start Y at one

```asm
ldy #$01
```

`ldy` means:

```text
LoaD Y register
```

The Y register is another 8-bit register.

In this lesson, Y holds the current character screen code.

We start Y at `$01` because screen code `$01` gives us the letter `A`.

Then we increase Y each time through the loop to get:

```text
$01, $02, $03, ... $10
```

which appears as:

```text
A, B, C, ... P
```

### Copy label

```asm
copy:
```

`copy` is a label.

It marks the beginning of the loop.

The program branches back to this label until 16 characters have been copied.

### Transfer Y to the accumulator

```asm
tya
```

`tya` means:

```text
Transfer Y to Accumulator
```

The accumulator is the register used by `sta`.

So before we can store the current character value into screen memory, we move it from Y into the accumulator.

The data flow is:

```text
Y -> accumulator
```

### Store character using indexed addressing

```asm
sta $0400,x
```

This is the main new idea in the lesson.

`sta $0400,x` means:

```text
Store the accumulator at address $0400 + X
```

So if X is `$00`, the store goes to `$0400`.

If X is `$01`, the store goes to `$0401`.

If X is `$02`, the store goes to `$0402`.

This lets the program walk across the first row of screen memory without writing each address manually.

### Set the character colour

```asm
lda #$01
sta $d800,x
```

`lda #$01` loads colour value `$01`, white.

`sta $d800,x` stores that colour at:

```text
$d800 + X
```

Colour RAM mirrors the screen memory position.

So when the character is stored at `$0400 + X`, its colour is stored at `$d800 + X`.

### Increment X

```asm
inx
```

`inx` means:

```text
INcrement X
```

This increases X by one.

That moves the next screen write one character cell to the right.

### Increment Y

```asm
iny
```

`iny` means:

```text
INcrement Y
```

This increases Y by one.

That moves the next character code forward.

So the next loop writes the next letter.

### Compare X with 16

```asm
cpx #$10
```

`cpx` means:

```text
ComPare X
```

`#$10` is hexadecimal for decimal 16.

This instruction compares X with `$10`.

It does not jump by itself.

It sets CPU flags based on the comparison.

The next instruction uses those flags.

### Branch if not equal

```asm
bne copy
```

`bne` means:

```text
Branch if Not Equal
```

It checks the result of the previous comparison.

Together:

```asm
cpx #$10
bne copy
```

means:

```text
Compare X with 16
If X is not 16, go back to copy
```

When X becomes `$10`, the branch is not taken.

The program continues to the next instruction.

### Return to BASIC

```asm
rts
```

`rts` means:

```text
ReTurn from Subroutine
```

Because BASIC started the machine code with `SYS`, `rts` returns control to BASIC.

This is different from the infinite loops in earlier lessons.

Here, the program does its work once and returns.

The screen contents remain visible because they were written into screen memory and colour RAM.

## The key idea

This lesson replaces manual repeated addresses:

```asm
sta $0400
sta $0401
sta $0402
```

with one indexed instruction:

```asm
sta $0400,x
```

That means:

```text
store at base address plus X
```

The same idea applies to colour RAM:

```asm
sta $d800,x
```

This means:

```text
store at colour RAM base plus X
```

So X is doing two jobs at once:

```text
screen position offset
colour position offset
```

Y is doing another job:

```text
current character value
```

And the accumulator is the value carrier used for stores.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/05-indexed-addressing
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
ABCDEFGHIJKLMNOP
```

in white on the top row.

After the program runs, it returns to BASIC.

That is expected.

## Machine concepts

This lesson introduces:

- Walking through screen memory using an offset
- Walking through colour RAM using the same offset
- Returning to BASIC after a machine-code routine has finished

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- Screen memory at `$0400`
- Colour RAM at `$d800`
- VIC-II border colour register at `$d020`
- VIC-II background colour register at `$d021`

## Assembly concepts

This lesson introduces:

- Absolute indexed addressing with X
- `ldy`
- `tya`
- `iny`
- `cpx`
- `bne`
- `rts`

It reuses:

- `lda`
- `ldx`
- `sta`
- `inx`
- Labels
- Immediate values with `#`
- Hexadecimal values with `$`

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
| `$0400-$040f` | First 16 screen memory cells on the top row |
| `$d800-$d80f` | Colour RAM for the first 16 screen cells |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the number of characters

Change:

```asm
cpx #$10
```

to:

```asm
cpx #$08
```

Build and run again.

Only eight characters should be copied.

### Change the starting character

Change:

```asm
ldy #$01
```

to:

```asm
ldy #$08
```

Build and run again.

The copied characters should start later in the screen-code sequence.

### Change the colour

Change:

```asm
lda #$01
sta $d800,x
```

to:

```asm
lda #$02
sta $d800,x
```

Build and run again.

The characters should become red instead of white.

### Start writing at another screen position

Change:

```asm
sta $0400,x
```

to:

```asm
sta $0428,x
```

And change:

```asm
sta $d800,x
```

to:

```asm
sta $d828,x
```

Build and run again.

The letters should appear on the second row.

### Remove `iny`

Remove:

```asm
iny
```

Build and run again.

The program should write the same character repeatedly, because Y no longer changes.

Put `iny` back afterwards.

### Replace `rts` with an infinite loop

Replace:

```asm
rts
```

with:

```asm
loop:
    jmp loop
```

Build and run again.

The visible result is the same, but the program does not return to BASIC.

This shows the difference between a routine that finishes and a program that stays running.

## Common mistakes

### Thinking `$0400,x` means the same as `$0400`

It does not.

```asm
sta $0400
```

always stores at `$0400`.

```asm
sta $0400,x
```

stores at `$0400 + X`.

### Forgetting that X and Y are separate

X controls where we write.

Y controls which character we write.

Changing X does not change Y.

Changing Y does not change X.

### Forgetting `tya`

`sta` stores the accumulator.

It does not store Y directly.

That is why this instruction matters:

```asm
tya
```

It copies Y into the accumulator before the screen write.

### Expecting `cpx` to branch by itself

`cpx` only compares.

It sets flags.

The branch instruction comes next:

```asm
bne copy
```

### Forgetting that `$10` is 16

`$10` is hexadecimal.

It equals decimal 16.

So:

```asm
cpx #$10
```

means:

```text
compare X with 16
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
06 - Bit operations and colour patterns
```

Now that we can walk across memory with X, we can generate patterns.

The next lesson will introduce a new idea:

```asm
and #$0f
```

That will let us keep only the lower 4 bits of a value and create a repeating 16-colour pattern.

This connects indexed addressing with the C64's 16 colour values.
