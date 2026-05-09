# Lesson 01b - BASIC loader

## Goal

Add a tiny BASIC loader so the C64 program can be started with:

```basic
RUN
```

instead of manually typing:

```basic
SYS 49152
```

The visible machine-code effect is the same as Lesson 01:

- Change the border colour
- Change the background colour
- Loop forever

The new learning is how a `.prg` file can contain a small BASIC launcher before the machine code.

## What you will build

You will build a C64 program with two parts:

```text
$0801 - BASIC loader
$080d - machine code
```

The BASIC loader is equivalent to:

```basic
10 SYS 2061
```

When the user types:

```basic
RUN
```

BASIC executes the `SYS 2061` command.

Decimal `2061` is hexadecimal `$080d`.

That is where the machine code starts.

## What this teaches

This lesson teaches how a machine-code program can be made easier to start from the normal C64 BASIC environment.

Lesson 01 used this structure:

```text
$c000 - machine code
```

and started it manually with:

```basic
SYS 49152
```

This lesson uses this structure:

```text
$0801 - BASIC loader
$080d - machine code
```

and starts it with:

```basic
RUN
```

The hardware effect is familiar.

The entry mechanism is new.

## Files

This lesson contains:

```text
platforms/c64/lessons/01b-basic-loader/
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

It has two sections:

1. BASIC loader
2. Machine code

## BASIC loader source

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

This manually creates a tiny BASIC program in memory.

The program is equivalent to:

```basic
10 SYS 2061
```

## Machine-code source

```asm
* = $080d

start:
    lda #$06
    sta $d020

    lda #$02
    sta $d021

loop:
    jmp loop
```

This is the familiar machine-code effect from Lesson 01, but now it starts at `$080d`.

## Code walkthrough

### BASIC program start

```asm
* = $0801
```

This is an assembler directive.

It tells KickAssembler to place the following bytes at C64 memory address `$0801`.

On the C64, `$0801` is the normal start address for BASIC programs.

Because we want the program to start with `RUN`, we first create a tiny BASIC program at this address.

### Pointer to the next BASIC line

```asm
.word basic_next_line
```

A BASIC line starts with a two-byte pointer to the next BASIC line.

This line writes the address of the label `basic_next_line`.

That tells BASIC where the next line would start.

Because we only have one line, the address points to the end marker.

### BASIC line number

```asm
.word 10
```

This writes the BASIC line number.

The line number is:

```basic
10
```

BASIC stores line numbers as two-byte values.

### BASIC token for SYS

```asm
.byte $9e
```

This writes one byte: `$9e`.

In C64 BASIC, `$9e` is the token for `SYS`.

BASIC does not store every keyword as plain text. Many keywords are stored as one-byte tokens.

So this byte represents the BASIC command:

```basic
SYS
```

### SYS target address as text

```asm
.text "2061"
```

This writes the characters:

```text
2 0 6 1
```

BASIC's `SYS` command expects a decimal address.

Decimal `2061` is hexadecimal `$080d`.

That is where the machine code will start.

### End of BASIC line

```asm
.byte 0
```

A zero byte marks the end of this BASIC line.

### End of BASIC program

```asm
basic_next_line:
    .word 0
```

`basic_next_line:` is a label.

It marks the address where the next BASIC line would begin.

At that address, we write:

```asm
.word 0
```

A zero next-line pointer means:

```text
There are no more BASIC lines.
```

So the whole BASIC program is complete.

### Machine-code start

```asm
* = $080d
```

This tells KickAssembler to place the following machine code at address `$080d`.

This must match the BASIC command:

```basic
SYS 2061
```

If these do not match, BASIC will jump to the wrong address.

### Load and store colour values

```asm
lda #$06
sta $d020

lda #$02
sta $d021
```

This is the same pattern as Lesson 01.

`lda #$06` loads colour value `$06` into the accumulator.

`sta $d020` stores it in the VIC-II border colour register.

`lda #$02` loads colour value `$02` into the accumulator.

`sta $d021` stores it in the VIC-II background colour register.

The result is:

```text
Border:     blue
Background: red
```

### Infinite loop

```asm
loop:
    jmp loop
```

This keeps the program alive.

Without a loop or a clean return, the CPU would continue into whatever bytes happen to follow the program.

For this lesson, staying in an infinite loop is the safest behaviour.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/01b-basic-loader
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

The program should change the border and background colours.

## Why RUN works now

In Lesson 01, the `.prg` contained only machine code at `$c000`.

So BASIC did not have a program line to run.

You had to type:

```basic
SYS 49152
```

In this lesson, the `.prg` starts with a valid BASIC line at `$0801`:

```basic
10 SYS 2061
```

So when you type:

```basic
RUN
```

BASIC runs that line.

That line then starts the machine code at `$080d`.

## Machine concepts

This lesson introduces:

- BASIC program start address `$0801`
- BASIC as a launcher for machine code
- `SYS` as the bridge from BASIC into machine code
- The difference between loading a program and starting a program
- How a `.prg` can contain both a BASIC loader and machine code

## Assembly concepts

This lesson introduces:

- `.word`
- `.byte`
- `.text`
- Labels used as addresses
- Storing raw bytes for BASIC
- Matching a BASIC `SYS` target with a machine-code start address

It reuses:

- `lda`
- `sta`
- `jmp`
- Immediate values
- The accumulator
- Memory-mapped I/O

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
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the BASIC line number

Change:

```asm
.word 10
```

to:

```asm
.word 20
```

Build and run again.

The program should still work.

The line number affects how BASIC lists and orders the program, but not the machine-code effect.

### List the BASIC program

After loading the program in VICE, type:

```basic
LIST
```

You should see something like:

```basic
10 SYS 2061
```

This confirms that our manually written bytes are recognised by BASIC as a real BASIC line.

### Change the colour values

Change:

```asm
lda #$06
```

or:

```asm
lda #$02
```

Build and run again.

The loader should still work.

Only the visible colours should change.

### Break the SYS address deliberately

Change:

```asm
.text "2061"
```

to another address, then build and run.

The program may fail or behave strangely because BASIC jumps to the wrong place.

Put it back afterwards.

This experiment shows why the BASIC loader and machine-code start address must match.

### Move the machine-code start deliberately

Change:

```asm
* = $080d
```

without changing:

```asm
.text "2061"
```

Build and run.

The program may fail because the `SYS` command still jumps to `$080d`.

Put it back afterwards.

## Common mistakes

### Confusing decimal and hexadecimal

BASIC uses:

```basic
SYS 2061
```

The assembler uses:

```asm
* = $080d
```

These are the same address written in two different number systems.

```text
2061 decimal = $080d hexadecimal
```

### Thinking `.word basic_next_line` and `.word 0` are the same

They are not the same.

```asm
.word basic_next_line
```

writes the address of the next BASIC line location.

```asm
basic_next_line:
    .word 0
```

marks that location and writes a zero pointer there, meaning there are no more BASIC lines.

The first one points forward.

The second one ends the program.

### Forgetting that `SYS` is BASIC

`SYS` is not an assembly instruction.

It is a BASIC command that tells BASIC to start executing machine code at an address.

### Expecting the visible effect to be different

The visible effect is intentionally the same as Lesson 01.

The learning in this lesson is not a new graphics trick.

The learning is the loader.

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
02 - CPU basics
```

Now that we have touched the machine and learned two ways to start code, we can slow down and look more carefully at the CPU.

The next lesson will focus on:

- The accumulator
- The X register
- The Y register
- Immediate values
- Memory addressing
- Labels
- Branching and looping
- Values versus addresses
