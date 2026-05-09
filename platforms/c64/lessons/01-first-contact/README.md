# Lesson 01 - First contact

## Goal

Write the first meaningful Commodore 64 assembly program.

The program changes the border colour and background colour by writing directly to VIC-II hardware registers.

This is the first direct contact with the machine.

## What you will build

You will build a small C64 machine-code program that:

- Loads at address `$c000`
- Changes the border colour
- Changes the background colour
- Loops forever so the result stays visible

The program is started manually from BASIC with:

```basic
SYS 49152
```

Decimal `49152` is hexadecimal `$c000`.

## What this teaches

This lesson teaches the first link between assembly code, memory, hardware, and visible output.

The important idea is:

```text
The CPU can change the machine by writing values to specific memory addresses.
```

On the C64, some memory addresses are not ordinary RAM.

Some addresses are connected to hardware.

This is called memory-mapped I/O.

In this lesson, the CPU writes to two VIC-II registers:

```text
$d020 - border colour
$d021 - background colour
```

## Files

This lesson contains:

```text
platforms/c64/lessons/01-first-contact/
├── README.md
├── main.asm
└── build.sh
```

Generated files such as `main.prg` are ignored by Git.

## Source code

The program is in:

```text
main.asm
```

Current version:

```asm
// Assembly from Scratch
// Platform: Commodore 64
// Lesson 01: First contact
//
// This is the first meaningful C64 assembly program.
//
// It changes the border colour and background colour by writing directly
// to the VIC-II colour registers.

* = $c000

start:
    lda #$06      // Load colour value $06 into the accumulator.
    sta $d020     // Store it in the VIC-II border colour register.

    lda #$02      // Load colour value $02 into the accumulator.
    sta $d021     // Store it in the VIC-II background colour register.

loop:
    jmp loop      // Stay here forever so the result remains visible.
```

## Code walkthrough

### Program start address

```asm
* = $c000
```

This is an assembler directive.

It is not a CPU instruction.

It tells KickAssembler:

```text
Assemble the following bytes as if they start at C64 memory address $c000.
```

`$c000` is hexadecimal.

In decimal, `$c000` is:

```text
49152
```

That is why the program is started from BASIC with:

```basic
SYS 49152
```

### Start label

```asm
start:
```

`start:` is a label.

A label gives a name to a position in the program.

It does not create a CPU instruction by itself.

In this lesson, the label is mostly there for readability. Later, labels will become more important when we branch, jump, and organise code.

### Load the border colour

```asm
lda #$06
```

`lda` means:

```text
LoaD Accumulator
```

The accumulator is the main 8-bit working register of the 6510 CPU.

`#$06` means:

```text
Use the immediate value $06.
```

The `#` is important.

It means "use this value directly".

So this instruction puts the value `$06` into the accumulator.

On the C64, colour value `$06` is blue.

### Store the border colour

```asm
sta $d020
```

`sta` means:

```text
STore Accumulator
```

This stores the value currently in the accumulator into address `$d020`.

On the C64, `$d020` is the VIC-II border colour register.

Because `$d020` is connected to video hardware, storing a value there changes the visible border colour.

This is memory-mapped I/O.

The CPU writes to an address, and the hardware reacts.

### Load the background colour

```asm
lda #$02
```

This loads a new value into the accumulator.

The accumulator holds one value at a time.

If we want to store a different value somewhere else, we must first load the new value.

On the C64, colour value `$02` is red.

### Store the background colour

```asm
sta $d021
```

This stores the accumulator into address `$d021`.

On the C64, `$d021` is the VIC-II background colour register.

Because the accumulator now contains `$02`, the background colour changes to colour `$02`.

### Infinite loop

```asm
loop:
    jmp loop
```

`loop:` is another label.

`jmp` means:

```text
JuMP
```

So:

```asm
jmp loop
```

means:

```text
Jump to the address marked by the label loop.
```

Because the instruction jumps back to itself, the program stays there forever.

This is intentional.

If the program did not loop or return cleanly, the CPU would continue executing whatever bytes happened to come next in memory.

That would be uncontrolled.

For this first lesson, the infinite loop keeps the visible result stable.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/01-first-contact
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

This produces:

```text
main.prg
```

Then, in the C64 emulator, start the program manually with:

```basic
SYS 49152
```

## Why SYS 49152?

The program is assembled to start at:

```asm
* = $c000
```

The C64 BASIC `SYS` command expects a decimal address.

Hexadecimal `$c000` equals decimal `49152`.

So:

```basic
SYS 49152
```

means:

```text
Start executing machine code at address $c000.
```

## Machine concepts

This lesson introduces:

- Loading a C64 `.prg` file
- Starting machine code manually from BASIC
- Memory-mapped I/O
- The VIC-II border colour register
- The VIC-II background colour register
- The difference between normal memory and hardware registers

## Assembly concepts

This lesson introduces:

- Assembler origin with `* =`
- Labels
- `lda`
- `sta`
- `jmp`
- Immediate values with `#`
- Hexadecimal values with `$`
- The accumulator
- Infinite loops

## Hardware registers used

| Address | Name | Purpose |
|---|---|---|
| `$d020` | VIC-II border colour register | Controls the border colour |
| `$d021` | VIC-II background colour register | Controls the background colour |

## Memory addresses used

| Address | Purpose |
|---|---|
| `$c000` | Start address for this machine-code program |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

Try these small changes:

### Change the border colour

Change:

```asm
lda #$06
sta $d020
```

to another colour value.

For example:

```asm
lda #$00
sta $d020
```

Build, run, and start again with:

```basic
SYS 49152
```

### Change the background colour

Change:

```asm
lda #$02
sta $d021
```

to another colour value.

### Use the same colour for both

Use one load and two stores:

```asm
lda #$06
sta $d020
sta $d021
```

This works because the accumulator still contains `$06` when the second `sta` runs.

### Use different colours

Use two loads and two stores:

```asm
lda #$06
sta $d020

lda #$02
sta $d021
```

This is needed when the border and background should use different values.

### Remove the `#`

Compare:

```asm
lda #$06
```

with:

```asm
lda $06
```

The first loads the value `$06`.

The second loads from memory address `$06`.

They are not the same instruction.

### Remove the loop

Remove:

```asm
loop:
    jmp loop
```

Then build and run again.

The result may become unstable because the CPU continues into whatever bytes happen to follow the program.

This is a useful experiment, but put the loop back afterwards.

## Common mistakes

### Forgetting the `#`

This loads the immediate value `$06`:

```asm
lda #$06
```

This loads from memory address `$06`:

```asm
lda $06
```

For this lesson, we want the immediate value.

### Using semicolon comments

Many 6502 assemblers use `;` for comments.

KickAssembler uses `//` for comments.

Use:

```asm
lda #$06      // Correct KickAssembler comment style.
```

Not:

```asm
lda #$06      ; This causes a syntax error in KickAssembler.
```

### Forgetting to start the program

Opening `main.prg` in VICE loads the program, but it does not automatically run this version.

You still need to type:

```basic
SYS 49152
```

### Expecting aliases inside build scripts

Shell aliases such as `kickass` and `x64sc-open` may work in the terminal but not inside scripts.

For this reason, the build script uses explicit commands:

```bash
java -jar ../../tools/kickassembler/KickAss.jar main.asm
open -a x64sc main.prg
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
02 - CPU basics
```

In the next lesson, we slow down and focus on the CPU itself.

We will look more carefully at:

- The accumulator
- The X and Y registers
- Immediate values
- Memory addressing
- Labels
- Simple loops
- The difference between values and addresses

This first lesson touched the machine.

The next lesson explains more of the CPU that made it happen.
