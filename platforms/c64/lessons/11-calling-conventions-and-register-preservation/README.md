# Lesson 11 - Calling conventions and register preservation

## Goal

Understand how subroutines communicate with callers.

A subroutine can change CPU registers.

If the caller expects a register to survive a subroutine call, either the caller must save it or the subroutine must preserve it.

The routine itself is not important in this lesson.

The contract between caller and routine is important.

## Project convention from this lesson

From this point forward, the project uses this convention:

```text
A, X, Y, and flags may be destroyed unless the routine says otherwise.

The caller saves what it needs.

The callee preserves only what it explicitly promises to preserve.
```

Every non-trivial routine should document:

```text
input
output
destroyed registers
preserved registers, if any
memory locations used
```

This is the baseline for writing clearer, more function-like assembly without pretending that the 6510 has modern function calls.

## What you will build

You will build a small C64 program that demonstrates three cases:

```text
1. An unsafe routine destroys X
2. The caller saves X before calling an unsafe routine
3. The callee preserves X internally
```

The expected visual result is:

```text
A               B
CD
EF
```

`B` does not appear next to `A`, because the called routine changed X.

`D` appears next to `C`, because the caller saved and restored X.

`F` appears next to `E`, because the called routine preserved X itself.

## What this teaches

This lesson teaches that subroutines are contracts.

A subroutine may destroy:

```text
A
X
Y
processor flags
memory locations
hardware state
```

Nothing is automatically safe.

A routine is safe only according to what it promises.

The important question is always:

```text
What does this routine expect?
What does it return?
What does it destroy?
What does it preserve?
```

## Files

This lesson contains:

```text
platforms/c64/lessons/11-calling-conventions-and-register-preservation/
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
// Lesson 11: Calling conventions and register preservation
//
// This lesson introduces calling conventions.
//
// A subroutine can change CPU registers.
// If the caller expects a register to survive a subroutine call,
// either the caller must save it or the subroutine must preserve it.
//
// The routine itself is not important here.
// The contract between caller and routine is important.
//
// Project convention from this lesson:
//
//   A, X, Y, and flags may be destroyed unless the routine says otherwise.
//   The caller saves what it needs.
//   The callee preserves only what it explicitly promises to preserve.
//
// Every non-trivial routine should document:
//
//   input
//   output
//   destroyed registers
//   preserved registers, if any
//   memory locations used

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

.encoding "screencode_upper"  // Convert .text strings to C64 uppercase screen codes

start:
    lda #$06                  // Load colour value $06, blue
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    jsr clear_screen          // Prepare a clean screen

// -----------------------------------------------------------------------------
// Case 1: caller assumes X survives, but it does not
// -----------------------------------------------------------------------------

    ldx #$00                  // Caller wants to use X as a screen offset

    lda #$01                  // Load screen code $01, the letter A
    sta $0400,x               // Write A at $0400 + X

    jsr destroys_x            // This routine destroys X

    lda #$02                  // Load screen code $02, the letter B
    sta $0401,x               // Caller expected X to still be $00

// -----------------------------------------------------------------------------
// Case 2: caller saves X before calling a routine that destroys it
// -----------------------------------------------------------------------------

    ldx #$00                  // Caller wants X to survive the call

    lda #$03                  // Load screen code $03, the letter C
    sta $0428,x               // Write C at row 1, column 0

    txa                       // Copy X into A
    pha                       // Push A onto the stack

    jsr destroys_x            // This routine destroys X

    pla                       // Pull saved X value back into A
    tax                       // Restore X

    lda #$04                  // Load screen code $04, the letter D
    sta $0429,x               // Write D at row 1, column 1 as expected

// -----------------------------------------------------------------------------
// Case 3: callee preserves X internally
// -----------------------------------------------------------------------------

    ldx #$00                  // Caller wants X to survive the call

    lda #$05                  // Load screen code $05, the letter E
    sta $0450,x               // Write E at row 2, column 0

    jsr preserves_x           // This routine preserves X

    lda #$06                  // Load screen code $06, the letter F
    sta $0451,x               // Write F at row 2, column 1 as expected

    rts                       // Return to BASIC

// -----------------------------------------------------------------------------
// Clear screen subroutine
// -----------------------------------------------------------------------------
//
// Input:
//
//   none
//
// Output:
//
//   screen memory filled with spaces
//   colour RAM initialised to white
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

    lda #$01                  // Load colour value $01, white
    sta $d800,x               // Initialise colour RAM page $d8
    sta $d900,x               // Initialise colour RAM page $d9
    sta $da00,x               // Initialise colour RAM page $da
    sta $db00,x               // Initialise colour RAM page $db

    inx                       // Move to the next position
    bne clear                 // Repeat until X wraps from $ff to $00

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Routine that destroys X
// -----------------------------------------------------------------------------
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
//   X
//   flags
//
// Preserves:
//
//   A
//   Y
//
// This routine deliberately changes X.
// It represents any routine that uses X internally and does not promise
// to preserve it.

destroys_x:
    ldx #$10                  // Destroy the caller's X value
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Routine that preserves X
// -----------------------------------------------------------------------------
//
// Input:
//
//   X - caller's X value
//
// Output:
//
//   none
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
// This routine saves X on the stack, uses X internally, then restores X
// before returning.
//
// It preserves X, but it uses A while doing so.
// Therefore it does not promise to preserve A.

preserves_x:
    txa                       // Copy X into A
    pha                       // Save X value on the stack

    ldx #$10                  // Use X internally

    pla                       // Restore saved X value into A
    tax                       // Copy A back to X

    rts                       // Return to the caller
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

### Machine-code start and encoding

```asm
* = $080d

.encoding "screencode_upper"
```

The machine code starts at `$080d`, matching the BASIC loader's `SYS 2061`.

The `.encoding` directive tells KickAssembler to convert `.text` strings into C64 uppercase screen codes.

### Prepare the display

```asm
lda #$06
sta $d020
sta $d021

jsr clear_screen
```

The program sets the border and background colour, then calls `clear_screen`.

`clear_screen` prepares a clean visible state before the demonstration writes anything.

## Case 1 - Caller assumes X survives, but it does not

```asm
ldx #$00

lda #$01
sta $0400,x

jsr destroys_x

lda #$02
sta $0401,x
```

The caller starts with:

```text
X = $00
```

Then it writes `A` at:

```text
$0400 + X = $0400
```

The caller then calls:

```asm
jsr destroys_x
```

The routine changes X to `$10`.

After the call, the caller writes `B` with:

```asm
sta $0401,x
```

The caller expected X to still be `$00`, so it expected the write to go to:

```text
$0401
```

But X is actually `$10`, so the write goes to:

```text
$0401 + $10 = $0411
```

That is why `B` appears in the wrong place.

The lesson:

```text
Do not assume a register survives a call unless the routine promises it.
```

## Case 2 - Caller saves what it needs

```asm
ldx #$00

lda #$03
sta $0428,x

txa
pha

jsr destroys_x

pla
tax

lda #$04
sta $0429,x
```

The caller needs X after the subroutine call.

The called routine does not promise to preserve X.

So the caller saves X before the call.

Because the 6510 stack can push and pull the accumulator, the caller first copies X into A:

```asm
txa
```

Then it pushes A onto the stack:

```asm
pha
```

After the call, it restores the value:

```asm
pla
tax
```

Now X is back to `$00`.

So `D` appears next to `C`.

The lesson:

```text
If the caller needs a register after a call, the caller can save it.
```

## Case 3 - Callee preserves what it promises

```asm
ldx #$00

lda #$05
sta $0450,x

jsr preserves_x

lda #$06
sta $0451,x
```

Here, the caller calls a routine that promises to preserve X.

The caller does not save X.

The routine itself handles that.

So `F` appears next to `E`.

The lesson:

```text
If the callee promises to preserve a register, it must actually preserve it.
```

## The stack

The stack is a special memory area used for temporary storage and return addresses.

On the 6510, the stack lives in page 1:

```text
$0100-$01ff
```

The instruction:

```asm
pha
```

means:

```text
Push Accumulator
```

It saves the current accumulator value on the stack.

The instruction:

```asm
pla
```

means:

```text
Pull Accumulator
```

It restores the most recently pushed value into the accumulator.

The stack is last-in, first-out.

That means the last value pushed is the first value pulled.

## Routine: clear_screen

```asm
clear_screen:
    ldx #$00

clear:
    lda #$20
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x

    lda #$01
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x

    inx
    bne clear

    rts
```

The routine contract is:

```text
Input:
  none

Output:
  screen memory filled with spaces
  colour RAM initialised to white

Destroys:
  A
  X
  flags

Preserves:
  Y

Memory used:
  $0400-$07ff
  $d800-$dbff
```

This is an example of a routine that does not preserve A or X.

That is fine because its contract says so.

## Routine: destroys_x

```asm
destroys_x:
    ldx #$10
    rts
```

The routine contract is:

```text
Input:
  none

Output:
  none

Destroys:
  X
  flags

Preserves:
  A
  Y
```

This routine deliberately changes X.

It represents any routine that uses X internally and does not promise to preserve it.

It also destroys flags because `ldx #$10` affects the zero and negative flags.

## Routine: preserves_x

```asm
preserves_x:
    txa
    pha

    ldx #$10

    pla
    tax

    rts
```

The routine contract is:

```text
Input:
  X - caller's X value

Output:
  none

Destroys:
  A
  flags

Preserves:
  X
  Y
```

This routine preserves X by saving it on the stack.

The sequence is:

```asm
txa
pha
```

which means:

```text
copy X to A
push A onto the stack
```

Then the routine can use X internally:

```asm
ldx #$10
```

Before returning, it restores X:

```asm
pla
tax
```

which means:

```text
pull saved value back into A
copy A back to X
```

This preserves X, but it uses A while doing so.

Therefore the routine does not promise to preserve A.

## Variants and best practices

There are several ways to handle registers.

### Variant 1 - Caller does not care

If the caller does not need a register after the call, do nothing.

```asm
jsr clear_screen
```

This is fine if the caller does not care that `clear_screen` destroys A and X.

### Variant 2 - Routine documents what it destroys

A routine can simply document its side effects:

```asm
// Destroys:
//
//   A
//   X
//   flags
```

This is often enough.

### Variant 3 - Caller saves what it needs

If only one caller needs a register to survive, the caller can save it:

```asm
txa
pha

jsr destroys_x

pla
tax
```

This keeps the callee simple.

### Variant 4 - Callee preserves what it promises

If many callers expect a register to survive, the routine can preserve it:

```asm
preserves_x:
    txa
    pha

    ldx #$10

    pla
    tax

    rts
```

This makes the routine easier to call, but it costs bytes and cycles.

### Variant 5 - Preserve A and X

If a routine promises to preserve both A and X:

```asm
preserve_ax:
    pha

    txa
    pha

    ldx #$10

    pla
    tax

    pla

    rts
```

The stack is last-in, first-out.

A is pushed first, X is pushed second.

So X must be restored first, then A.

### Variant 6 - Preserve A, X, and Y

To preserve all three main registers:

```asm
preserve_axy:
    pha

    txa
    pha

    tya
    pha

    ldx #$10

    pla
    tay

    pla
    tax

    pla

    rts
```

This is safer, but longer and slower.

Preserving everything is not always better.

### Variant 7 - Preserve flags too

Processor flags can be saved with:

```asm
php
```

and restored with:

```asm
plp
```

Example:

```asm
preserve_axy_flags:
    php

    pha
    txa
    pha
    tya
    pha

    ldx #$10

    pla
    tay
    pla
    tax
    pla

    plp

    rts
```

This preserves A, X, Y, and flags.

It is the most defensive version, but also the most expensive.

## The key rule

Do not preserve registers automatically.

Preserve registers when the routine promises to preserve them.

Otherwise, document what the routine destroys.

The project rule is:

```text
No hidden assumptions.
No automatic preservation.
Every routine has a contract.
```

## Why not preserve everything all the time?

Preserving registers costs:

```text
bytes
cycles
complexity
```

On a small machine, those costs matter.

A fast routine in a raster effect may deliberately destroy everything.

A friendly utility routine may preserve more.

Both can be correct if the contract is clear.

## What about self-modifying code?

Self-modifying code is not covered in this lesson.

It is a real and important C64 technique, especially in demos.

The basic idea is to patch instruction operands at runtime, for example changing:

```asm
sta $0400
```

into something equivalent to:

```asm
sta $0428
```

by modifying the address bytes in the instruction.

That is powerful, but it requires a stronger understanding of instruction bytes, operands, labels, and code as data.

We will cover it later, once the foundation is ready.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/11-calling-conventions-and-register-preservation
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

You should see that `B` is not next to `A`, while `D` is next to `C`, and `F` is next to `E`.

## Machine concepts

This lesson introduces:

- Routine contracts
- Register preservation
- Register destruction
- The stack at `$0100-$01ff`
- Caller-saves versus callee-saves thinking
- Flags as part of routine side effects

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- Screen memory
- Colour RAM
- Subroutines
- `jsr` and `rts`

## Assembly concepts

This lesson introduces:

- `pha`
- `pla`
- Saving X via `txa` and `pha`
- Restoring X via `pla` and `tax`
- `php`
- `plp`
- Calling convention documentation

It reuses:

- `lda`
- `ldx`
- `sta`
- `inx`
- `bne`
- `jsr`
- `rts`
- indexed addressing with X

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$0100-$01ff` | CPU stack page |
| `$0400-$07ff` | Screen memory pages cleared by `clear_screen` |
| `$d800-$dbff` | Colour RAM pages initialised by `clear_screen` |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the destroyed X value

Change:

```asm
ldx #$10
```

inside `destroys_x` to:

```asm
ldx #$05
```

Build and run again.

The misplaced `B` should move.

### Remove the caller save

In case 2, remove:

```asm
txa
pha
```

and:

```asm
pla
tax
```

Build and run again.

`D` should no longer appear next to `C`.

### Break the callee preservation

In `preserves_x`, remove:

```asm
pla
tax
```

Build and run again.

`F` should no longer appear next to `E`.

### Preserve A and X

Add a new routine that preserves both A and X using the pattern in the README.

Call it and confirm that both values survive.

### Preserve flags

Add a small experiment with `php` and `plp`.

This is optional for now, because flags will become more important in later lessons.

## Common mistakes

### Thinking `jsr` protects registers

It does not.

`jsr` only saves the return address.

It does not save A, X, Y, or flags.

### Forgetting that `pha` only pushes A

There is no direct `phx` or `phy` on the original 6502/6510.

To save X, copy X to A first:

```asm
txa
pha
```

To restore X:

```asm
pla
tax
```

### Pulling values in the wrong order

The stack is last-in, first-out.

If you push A, then X, then Y, you must pull Y, then X, then A.

### Forgetting that flags change

Instructions like `lda`, `ldx`, `tax`, `inx`, and `dex` can change flags.

Unless a routine promises to preserve flags, assume flags are destroyed.

### Preserving too much

Preserving every register in every routine is safe but wasteful.

It costs bytes and cycles.

Choose deliberately.

## What comes next

Next lesson:

```text
12 - Tables and data-driven routines
```

Now that routine contracts are explicit, we can start making routines more useful by feeding them structured data.

The next natural step is to let data drive what appears on the screen, instead of hard-coding every setup sequence.
