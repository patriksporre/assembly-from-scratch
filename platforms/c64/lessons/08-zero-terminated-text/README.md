# Lesson 08 - Zero-terminated text

## Goal

Write readable text to the Commodore 64 screen.

The message is stored as data in the source file.

The program copies that data to screen memory until it finds a zero byte.

This is called zero-terminated text.

## What you will build

You will build a small C64 program that:

- Starts with `RUN`
- Sets the border and background colour
- Stores a readable message in the source file
- Converts that message to C64 screen codes with KickAssembler
- Copies the message to screen memory
- Sets the colour of each character
- Stops copying when it finds a zero byte
- Returns cleanly to BASIC with `rts`

The expected result is:

```text
HELLO, C64
```

in white on the top row.

## What this teaches

This lesson teaches how to treat text as data.

Earlier lessons wrote character values directly:

```asm
lda #$01
sta $0400
```

That works, but it does not scale well for real messages.

This lesson stores the message once:

```asm
message:
    .text "HELLO, C64"
    .byte 0
```

and copies it with a loop.

The key idea is:

```text
Data can be read one byte at a time until an end marker is found
```

Here, the end marker is:

```text
0
```

## Files

This lesson contains:

```text
platforms/c64/lessons/08-zero-terminated-text/
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
// Lesson 08: Zero-terminated text
//
// This lesson writes a short message to the screen.
//
// The message is stored as readable text in the source file.
// KickAssembler converts that text into C64 screen codes.
//
// The message ends with a zero byte.
//
// This is called zero-terminated text.
//
// The program copies bytes until it finds zero.

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

    ldx #$00                  // Start X at zero

copy:
    lda message,x             // Load one byte from the message
    beq done                  // If the byte is zero, the message is finished

    sta $0400,x               // Store the message byte at screen memory $0400 + X

    lda #$01                  // Load colour value $01, white
    sta $d800,x               // Store it at colour RAM $d800 + X

    inx                       // Move to the next character
    jmp copy                  // Continue copying

done:
    rts                       // Return to BASIC

message:
    .text "HELLO, C64"        // Message encoded as C64 screen codes
    .byte 0                   // Zero terminator
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

### Text encoding

```asm
.encoding "screencode_upper"
```

This is a KickAssembler directive.

It is not a 6510 CPU instruction.

It tells KickAssembler how to convert `.text` strings into bytes.

In this lesson, we use:

```asm
.encoding "screencode_upper"
```

so readable strings such as:

```asm
.text "HELLO, C64"
```

are converted into C64 uppercase screen codes.

This matters because screen memory does not use normal modern text encoding.

It uses C64 screen codes.

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

The accumulator still contains `$06` after the first `sta`, so the same value can be stored again without another `lda`.

### Start X at zero

```asm
ldx #$00
```

X is used as an offset into the message, screen memory, and colour RAM.

Starting X at zero means the first copy uses:

```text
message + 0
$0400 + 0
$d800 + 0
```

### Copy label

```asm
copy:
```

`copy` is a label.

It marks the start of the loop that copies the message to the screen.

### Load one byte from the message

```asm
lda message,x
```

This uses indexed addressing.

It means:

```text
load from message + X
```

So:

```text
X = $00 -> load the first byte of message
X = $01 -> load the second byte of message
X = $02 -> load the third byte of message
```

The loaded byte goes into the accumulator.

### Check for the zero terminator

```asm
beq done
```

`beq` means:

```text
Branch if Equal
```

In this context, it means:

```text
If the byte just loaded was zero, branch to done
```

Why?

Because `lda` updates the CPU zero flag.

If `lda message,x` loads zero, the zero flag is set.

Then `beq done` branches.

So these two lines are the heart of the zero-terminated text loop:

```asm
lda message,x
beq done
```

They mean:

```text
Load the next message byte
If it is zero, stop copying
```

### Store the character to screen memory

```asm
sta $0400,x
```

If the loaded byte was not zero, it is a character screen code.

This stores it at:

```text
$0400 + X
```

That places the character on the top row.

### Set the character colour

```asm
lda #$01
sta $d800,x
```

`lda #$01` loads colour value `$01`, white.

`sta $d800,x` stores it at:

```text
$d800 + X
```

That gives the current character its colour.

### Move to the next character

```asm
inx
```

This increases X by one.

The next pass through the loop reads the next message byte and writes to the next screen cell.

### Continue copying

```asm
jmp copy
```

This jumps back to the start of the copy loop.

The loop continues until a zero byte is found.

### Return to BASIC

```asm
done:
    rts
```

When the zero terminator is found, the program branches to `done`.

`rts` returns control to BASIC.

The message remains visible because it has already been written to screen memory and colour RAM.

### Message data

```asm
message:
    .text "HELLO, C64"
    .byte 0
```

The `.text` directive writes the message bytes.

Because the source uses:

```asm
.encoding "screencode_upper"
```

KickAssembler converts the readable text into C64 uppercase screen codes.

The final byte:

```asm
.byte 0
```

is the zero terminator.

It is not displayed.

It tells the copy loop where the message ends.

## The key idea

The message has no explicit length in the code.

Instead, the message marks its own end:

```asm
.byte 0
```

The loop does not need to know whether the message has 3 characters, 10 characters, or 30 characters.

It only needs this rule:

```text
copy bytes until a zero byte is found
```

That is the essence of zero-terminated text.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/08-zero-terminated-text
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
HELLO, C64
```

in white on the top row.

After the program runs, it returns to BASIC.

That is expected.

## Machine concepts

This lesson introduces:

- Text as data
- C64 screen-code text output
- Zero-terminated messages
- Copying data to screen memory
- Using colour RAM alongside text output

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- Screen memory at `$0400`
- Colour RAM at `$d800`
- VIC-II border colour register at `$d020`
- VIC-II background colour register at `$d021`

## Assembly concepts

This lesson introduces:

- `.encoding`
- `.text`
- `beq`
- Zero-terminated data

It reuses:

- `lda`
- `ldx`
- `sta`
- `inx`
- `jmp`
- `rts`
- Indexed addressing with X
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
| `$0400` onward | Screen memory used for the message |
| `$d800` onward | Colour RAM used for the message |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the message

Change:

```asm
.text "HELLO, C64"
```

to:

```asm
.text "ASSEMBLY!"
```

Build and run again.

The new message should appear.

### Change the colour

Change:

```asm
lda #$01
```

before the colour RAM write to another colour value.

For example:

```asm
lda #$02
```

Build and run again.

The message should change colour.

### Move the message to the second row

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

The message should appear on the second row.

### Remove the zero terminator

Remove:

```asm
.byte 0
```

Build and run again.

The program may continue copying whatever bytes happen to follow the message in memory until it eventually finds a zero.

This is a useful mistake.

It shows why the terminator matters.

Put the terminator back afterwards.

### Put the terminator earlier

Change:

```asm
message:
    .text "HELLO, C64"
    .byte 0
```

to:

```asm
message:
    .text "HELLO"
    .byte 0
    .text ", C64"
```

Build and run again.

Only `HELLO` should appear, because the zero byte stops the copy loop.

## Common mistakes

### Forgetting the zero terminator

Without:

```asm
.byte 0
```

the copy loop does not know where the message ends.

### Thinking `.text` writes ASCII directly to the C64 screen

The `.text` directive writes bytes.

The `.encoding` directive tells KickAssembler how to convert the readable string into bytes.

For this lesson, we use C64 uppercase screen codes.

### Thinking `beq` compares directly with zero

`beq` does not contain a value to compare with.

It checks the CPU zero flag.

The zero flag was set or cleared by the previous `lda`.

### Forgetting that `sta` stores the accumulator

The message byte is in the accumulator after:

```asm
lda message,x
```

That is why:

```asm
sta $0400,x
```

stores the current character.

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
09 - Text positioning
```

Now that we can copy a zero-terminated message, the next useful step is to place text intentionally.

That means writing messages at chosen screen positions, such as:

```text
row 5, column 10
```

At first, we will do that with known addresses.

Later, we can calculate addresses from row and column.
