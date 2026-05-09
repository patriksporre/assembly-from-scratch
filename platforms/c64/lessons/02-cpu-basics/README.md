# Lesson 02 - CPU basics

## Goal

Introduce the first working mental model of the C64 CPU.

The CPU has small internal registers.

Instructions move values into and out of those registers.

Some instructions change values.

Some instructions change what code runs next.

In this lesson, we use the X register and the accumulator to change the border colour repeatedly.

## What you will build

You will build a small C64 program that:

- Starts with `RUN`
- Loads a value into the X register
- Copies X into the accumulator
- Stores the accumulator into the VIC-II border colour register
- Increments X
- Repeats forever

The visible result is a quickly changing border colour.

This is not proper animation yet.

It is a CPU exercise that produces a visible hardware effect.

## What this teaches

This lesson teaches the first basic data path through the CPU:

```text
X register -> accumulator -> hardware register -> visible colour
```

It also teaches the first basic control path:

```text
label -> instructions -> jump back to label -> repeat
```

The important idea is:

```text
The CPU works by moving and changing small values.
```

In Lesson 01, we loaded fixed colour values.

In this lesson, the CPU changes a value repeatedly.

## Files

This lesson contains:

```text
platforms/c64/lessons/02-cpu-basics/
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
// Lesson 02: CPU basics
//
// This lesson introduces the first working mental model of the 6510 CPU.
//
// The CPU has small internal registers.
// Instructions move values into and out of those registers.
// Some instructions change values.
// Some instructions change what code runs next.
//
// This program changes the border colour repeatedly by using the accumulator
// and the X register.

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
    ldx #$00                  // Load the immediate value $00 into the X register

colour_loop:
    txa                       // Transfer X to the accumulator
    sta $d020                 // Store the accumulator in the border colour register
    inx                       // Increment X by one
    jmp colour_loop           // Repeat forever
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

### Start label

```asm
start:
```

`start:` is a label.

It marks the beginning of the machine-code program.

A label is a name for an address.

It does not create a CPU instruction by itself.

### Load X

```asm
ldx #$00
```

`ldx` means:

```text
LoaD X register
```

The X register is one of the 6510 CPU's 8-bit registers.

The `#` means immediate value.

So:

```asm
ldx #$00
```

means:

```text
Put the value $00 directly into the X register
```

It does not mean "load from memory address `$00`".

That would be:

```asm
ldx $00
```

For this lesson, we want the immediate value.

### Loop label

```asm
colour_loop:
```

This label marks the beginning of the repeated part of the program.

Later, the program jumps back to this label.

This creates a loop.

### Transfer X to the accumulator

```asm
txa
```

`txa` means:

```text
Transfer X to Accumulator
```

After this instruction, the accumulator contains the same value as the X register.

The accumulator is the main working register of the 6510 CPU.

In this lesson, X holds the changing value.

The accumulator is used as the value that gets stored into the VIC-II border colour register.

The data path is:

```text
X -> accumulator
```

### Store accumulator into border colour

```asm
sta $d020
```

`sta` means:

```text
STore Accumulator
```

This stores the accumulator into address `$d020`.

On the C64, `$d020` is the VIC-II border colour register.

Because `$d020` is connected to video hardware, writing to it changes the visible border colour.

The data path is now:

```text
X -> accumulator -> $d020 -> border colour
```

### Increment X

```asm
inx
```

`inx` means:

```text
INcrement X
```

It adds one to the X register.

If X contains `$00`, it becomes `$01`.

If X contains `$01`, it becomes `$02`.

The X register is 8-bit, so it can hold values from:

```text
$00 to $ff
```

After `$ff`, it wraps around to `$00`.

That gives us an endless changing value.

### Jump back to the loop

```asm
jmp colour_loop
```

`jmp` means:

```text
JuMP
```

This sends execution back to the address marked by `colour_loop`.

So the CPU repeats:

```text
copy X to accumulator
store accumulator into border colour
increment X
jump back
```

forever.

## What the program does

The CPU executes this loop very quickly:

```asm
colour_loop:
    txa
    sta $d020
    inx
    jmp colour_loop
```

Each time through the loop:

1. X is copied into the accumulator
2. The accumulator is stored into the border colour register
3. X is increased
4. The program jumps back and repeats

Because the border colour is updated very quickly, the visible result is a rapidly changing border.

There is no timing control yet.

There is no waiting for a frame.

There is no raster synchronisation.

That is fine.

Timing comes later.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/02-cpu-basics
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

The border colour should change very quickly.

## Machine concepts

This lesson introduces:

- The CPU as a processor of small values
- The X register as an internal CPU register
- The accumulator as another internal CPU register
- Moving a value between registers
- Writing a changing value to a hardware register
- A simple infinite loop

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- VIC-II border colour register at `$d020`

## Assembly concepts

This lesson introduces:

- `ldx`
- `txa`
- `inx`

It reuses:

- `sta`
- `jmp`
- Labels
- Immediate values with `#`
- Hexadecimal values with `$`
- The accumulator
- Infinite loops

## Hardware registers used

| Address | Name | Purpose |
|---|---|---|
| `$d020` | VIC-II border colour register | Controls the border colour |

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$d020` | VIC-II border colour register |

## Experiments

### Change the starting value

Change:

```asm
ldx #$00
```

to:

```asm
ldx #$06
```

Build and run again.

The colour sequence starts from a different value.

### Count down instead of up

Change:

```asm
inx
```

to:

```asm
dex
```

`dex` means:

```text
DEcrement X
```

Instead of counting upward:

```text
$00, $01, $02, $03...
```

the X register counts downward:

```text
$00, $ff, $fe, $fd...
```

The border still changes, but the sequence runs in the opposite direction.

Put `inx` back afterwards if you want to keep the lesson source in its original form.

### Store to the background instead

Change:

```asm
sta $d020
```

to:

```asm
sta $d021
```

Now the background colour changes instead of the border colour.

### Store to both border and background

Use:

```asm
txa
sta $d020
sta $d021
inx
jmp colour_loop
```

This changes both the border and background using the same value.

### Remove `txa`

Remove:

```asm
txa
```

Build and run again.

The border may no longer change as expected because the accumulator is no longer being updated from X.

This shows that changing X does not automatically change the accumulator.

Each register is separate.

Put `txa` back afterwards.

## Common mistakes

### Thinking X and the accumulator are the same

They are not the same.

X and the accumulator are separate 8-bit registers.

Changing X does not automatically change the accumulator.

That is why this instruction matters:

```asm
txa
```

It copies the value from X into the accumulator.

### Forgetting the `#`

This loads the value `$00` into X:

```asm
ldx #$00
```

This loads X from memory address `$00`:

```asm
ldx $00
```

For this lesson, we want the immediate value.

### Expecting controlled animation

The colour changes very quickly because there is no delay and no timing control.

This lesson is about the CPU loop, not animation timing.

Timing comes later.

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
03 - Memory map
```

We have now touched hardware registers and used CPU registers.

Next, we need to understand the C64 memory map more clearly.

That means asking:

- What is RAM?
- What is ROM?
- What is I/O?
- Why does writing to `$d020` change hardware?
- Where does BASIC live?
- Where does screen memory live?
- Why are some addresses ordinary memory while others control the machine?

This will help us understand why the same CPU instructions can either store data or control hardware depending on the address.
