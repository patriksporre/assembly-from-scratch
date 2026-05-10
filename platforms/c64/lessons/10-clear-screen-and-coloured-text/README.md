# Lesson 10 - Clear screen and coloured text

## Goal

Prepare a clean screen, then print one zero-terminated message with colour.

This lesson combines three ideas:

```text
screen initialisation
subroutines
coloured text output
```

The result is a small structured program rather than a single isolated routine.

## What you will build

You will build a C64 program that:

- Starts with `RUN`
- Sets the border and background colour
- Clears the visible character screen
- Initialises colour RAM
- Prints one zero-terminated message
- Gives that message its own colour
- Returns cleanly to BASIC

The expected result is:

```text
ASSEMBLY FROM SCRATCH
```

printed on a clean screen.

## What this teaches

Lesson 09 introduced a reusable print routine with two pointers:

```text
message_ptr - where the message starts
screen_ptr  - where the text should appear
```

This lesson adds:

```text
colour_ptr   - where the character colours should be written
clear_colour - colour used for the initial display state
text_colour  - colour used by the print routine
clear_screen - a subroutine that prepares the screen before drawing
```

The program now has a clearer structure:

```text
start
  initialise display colours
  clear screen
  set print inputs
  print message
  return to BASIC
```

This is the first step toward organising assembly programs into routines with separate responsibilities.

## About routine inputs

This lesson passes routine inputs through named memory locations:

```asm
message_ptr
screen_ptr
colour_ptr
clear_colour
text_colour
```

That is simple and common on 6502-style machines.

It is also shared state.

That means the routines depend on values stored in known memory locations before they are called.

This is acceptable for this stage because it keeps the code readable and the machine behaviour visible.

Later lessons will introduce cleaner calling conventions, register preservation, stack use with `pha` and `pla`, and when routines should preserve or destroy registers.

For now, each routine documents its inputs and which registers it destroys.

## Files

This lesson contains:

```text
platforms/c64/lessons/10-clear-screen-and-coloured-text/
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
// Lesson 10: Clear screen and coloured text
//
// This lesson combines screen initialisation, subroutines, and coloured text.
//
// Lesson 09 introduced a reusable print routine using:
//
//   message_ptr - where the message starts
//   screen_ptr  - where the text should appear
//
// This lesson adds:
//
//   colour_ptr   - where the character colours should be written
//   clear_colour - colour used for the initial display state
//   text_colour  - colour used by the print routine
//   clear_screen - a subroutine that prepares the screen before drawing
//
// The program now has a simple structure:
//
//   initialise display
//   clear screen
//   print coloured text
//   return to BASIC
//
// The routine inputs are stored in named memory locations.
// This is simple and common on 6502-style machines, but it is shared state.
// Later lessons will introduce clearer calling conventions, register
// preservation, and stack use when those concepts have earned their place.

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
// Zero-page pointers
// -----------------------------------------------------------------------------
//
// These constants name zero-page addresses used as two-byte pointers.
//
// message_ptr uses $fb-$fc.
// screen_ptr uses $fd-$fe.
// colour_ptr uses $02-$03.
//
// The indirect indexed addressing mode:
//
//   (pointer),y
//
// requires the pointer to live in zero page.
//
// We use $fb-$fe because they are commonly available as zero-page workspace.
// We use $02-$03 for the third pointer in this controlled lesson.
// Do not assume that all zero page is free.

.const message_ptr = $fb
.const screen_ptr  = $fd
.const colour_ptr  = $02

// -----------------------------------------------------------------------------
// Machine code
// -----------------------------------------------------------------------------

* = $080d

.encoding "screencode_upper"  // Convert .text strings to C64 uppercase screen codes

start:
    lda clear_colour          // Load the colour used for the initial display state
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    jsr clear_screen          // Clear screen memory and initialise colour RAM

    lda #<message             // Load low byte of message address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message             // Load high byte of message address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0428               // Load low byte of screen address $0428
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0428               // Load high byte of screen address $0428
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    lda #<$d828               // Load low byte of colour RAM address $d828
    sta colour_ptr            // Store it in the low byte of colour_ptr
    lda #>$d828               // Load high byte of colour RAM address $d828
    sta colour_ptr + 1        // Store it in the high byte of colour_ptr

    lda #$01                  // Load colour value $01, white
    sta text_colour           // Store it as the current text colour

    jsr print                 // Print the message

    rts                       // Return to BASIC

// -----------------------------------------------------------------------------
// Clear screen subroutine
// -----------------------------------------------------------------------------
//
// Clears the visible character screen by filling screen memory with spaces.
//
// Input:
//
//   clear_colour - colour value used for border, background, and cleared cells
//
// Uses:
//
//   A - current value being written
//   X - offset into screen memory and colour RAM
//
// Destroys:
//
//   A
//   X
//
// This routine fills four 256-byte pages:
//
//   screen memory: $0400-$07ff
//   colour RAM:    $d800-$dbff
//
// The visible screen uses the first 1000 bytes.
// This routine fills 1024 bytes because that is simple and page-aligned.

clear_screen:
    ldx #$00                  // Start X at zero

clear:
    lda #$20                  // Load screen code $20, space
    sta $0400,x               // Clear screen page $04
    sta $0500,x               // Clear screen page $05
    sta $0600,x               // Clear screen page $06
    sta $0700,x               // Clear screen page $07

    lda clear_colour          // Load colour used for cleared cells
    sta $d800,x               // Initialise colour RAM page $d8
    sta $d900,x               // Initialise colour RAM page $d9
    sta $da00,x               // Initialise colour RAM page $da
    sta $db00,x               // Initialise colour RAM page $db

    inx                       // Move to the next position
    bne clear                 // Repeat until X wraps from $ff to $00

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Print subroutine
// -----------------------------------------------------------------------------
//
// Prints a zero-terminated message to screen memory and colour RAM.
//
// Input:
//
//   message_ptr - address of the zero-terminated message
//   screen_ptr  - address where the message should appear
//   colour_ptr  - address where the character colours should be written
//   text_colour - colour value to use for the message
//
// Uses:
//
//   A - current character or colour value
//   Y - offset into the message, screen position, and colour position
//
// Destroys:
//
//   A
//   Y

print:
    ldy #$00                  // Start Y at zero

copy:
    lda (message_ptr),y       // Load one byte from message_ptr + Y
    beq done                  // If the byte is zero, the message is finished

    sta (screen_ptr),y        // Store the byte at screen_ptr + Y

    lda text_colour           // Load the current text colour
    sta (colour_ptr),y        // Store it at colour_ptr + Y

    iny                       // Move to the next character
    jmp copy                  // Continue copying

done:
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Message and colour data
// -----------------------------------------------------------------------------

clear_colour:
    .byte $06                 // Colour used for border, background, and cleared cells

text_colour:
    .byte $01                 // Current text colour used by the print routine

message:
    .text "ASSEMBLY FROM SCRATCH"
    .byte 0
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

### Zero-page pointer constants

```asm
.const message_ptr = $fb
.const screen_ptr  = $fd
.const colour_ptr  = $02
```

These constants name zero-page addresses.

Each pointer uses two bytes:

| Pointer | Bytes used |
|---|---|
| `message_ptr` | `$fb-$fc` |
| `screen_ptr` | `$fd-$fe` |
| `colour_ptr` | `$02-$03` |

The indirect indexed addressing mode:

```asm
(pointer),y
```

requires the pointer to live in zero page.

`$fb-$fe` are commonly available as zero-page workspace. `$02-$03` are used here for the third pointer in this controlled lesson.

Do not assume the whole zero page is free.

### Machine-code start and encoding

```asm
* = $080d

.encoding "screencode_upper"
```

The machine code starts at `$080d`, matching the BASIC loader's `SYS 2061`.

The `.encoding` directive tells KickAssembler to convert `.text` strings into C64 uppercase screen codes.

### Start routine

```asm
start:
    lda clear_colour
    sta $d020
    sta $d021

    jsr clear_screen
```

The program begins by loading `clear_colour`.

It stores that colour into both:

```text
$d020 - border colour
$d021 - background colour
```

Then it calls:

```asm
jsr clear_screen
```

`clear_screen` prepares the screen before the program prints anything.

### Setting up the message pointer

```asm
lda #<message
sta message_ptr
lda #>message
sta message_ptr + 1
```

A C64 address is 16 bits, so a pointer needs two bytes.

The 6510 stores 16-bit addresses in little-endian order:

```text
low byte first
high byte second
```

KickAssembler's `<` and `>` operators extract those bytes:

```text
<address = low byte
>address = high byte
```

So the code stores the address of `message` into `message_ptr`.

### Setting up the screen pointer

```asm
lda #<$0428
sta screen_ptr
lda #>$0428
sta screen_ptr + 1
```

This stores the screen destination `$0428` into `screen_ptr`.

The C64 screen is 40 columns wide.

So:

```text
$0428 = $0400 + 40
```

That is row 1, column 0.

The message is placed on the second row.

### Setting up the colour pointer

```asm
lda #<$d828
sta colour_ptr
lda #>$d828
sta colour_ptr + 1
```

This stores the matching colour RAM destination into `colour_ptr`.

Colour RAM mirrors the screen position:

```text
$0400 -> $d800
$0428 -> $d828
```

So the character written at `$0428 + Y` gets its colour from `$d828 + Y`.

### Setting the text colour

```asm
lda #$01
sta text_colour
```

This stores the colour value used by the print routine.

`$01` is white.

The print routine reads `text_colour` once per character and writes that value into colour RAM.

### Calling the print routine

```asm
jsr print
```

This calls the reusable print routine.

Before the call, the program has set:

```text
message_ptr
screen_ptr
colour_ptr
text_colour
```

The routine uses those values as its inputs.

### Returning to BASIC

```asm
rts
```

After the message is printed, the program returns to BASIC.

The screen remains changed because the program has written to screen memory and colour RAM.

## Clear screen subroutine

```asm
clear_screen:
    ldx #$00

clear:
    lda #$20
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x

    lda clear_colour
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x

    inx
    bne clear

    rts
```

This subroutine clears the screen and initialises colour RAM.

### Space screen code

```asm
lda #$20
```

In C64 screen codes, `$20` is space.

Clearing the screen means filling screen memory with spaces.

### Four screen pages

```asm
sta $0400,x
sta $0500,x
sta $0600,x
sta $0700,x
```

These stores fill four 256-byte pages:

```text
$0400-$04ff
$0500-$05ff
$0600-$06ff
$0700-$07ff
```

That is 1024 bytes.

The visible screen uses the first 1000 bytes.

The extra 24 bytes are beyond the visible default screen area. This is simple and page-aligned, so it is acceptable for this lesson.

### Colour RAM initialisation

```asm
lda clear_colour
sta $d800,x
sta $d900,x
sta $da00,x
sta $db00,x
```

This initialises colour RAM over the same four-page pattern.

Even though spaces are not visible as characters, initialising colour RAM gives the screen a known state before later drawing happens.

### Routine side effects

`clear_screen` uses and destroys:

```text
A
X
```

That means callers should not expect A or X to hold the same values after calling it.

## Print subroutine

```asm
print:
    ldy #$00

copy:
    lda (message_ptr),y
    beq done

    sta (screen_ptr),y

    lda text_colour
    sta (colour_ptr),y

    iny
    jmp copy

done:
    rts
```

This routine prints a zero-terminated message and writes colour RAM for each character.

### Y as offset

Y starts at zero and moves through the message one character at a time.

```text
Y = 0 -> first character
Y = 1 -> second character
Y = 2 -> third character
```

### Loading from the message pointer

```asm
lda (message_ptr),y
```

This loads from:

```text
address stored in message_ptr + Y
```

If that byte is zero, the message is finished.

### Writing to the screen pointer

```asm
sta (screen_ptr),y
```

This stores the character at:

```text
address stored in screen_ptr + Y
```

### Writing to the colour pointer

```asm
lda text_colour
sta (colour_ptr),y
```

This loads the current text colour and stores it at:

```text
address stored in colour_ptr + Y
```

This gives each printed character its colour.

### Routine side effects

`print` uses and destroys:

```text
A
Y
```

That means callers should not expect A or Y to hold the same values after calling it.

## Message and colour data

```asm
clear_colour:
    .byte $06

text_colour:
    .byte $01

message:
    .text "ASSEMBLY FROM SCRATCH"
    .byte 0
```

`clear_colour` is used by the main program and by `clear_screen`.

`text_colour` is used by `print`.

`message` is zero-terminated text.

The `.text` directive writes the message bytes using the active C64 screen-code encoding.

The final zero byte marks the end of the message.

## The key idea

This lesson introduces simple program structure:

```text
start coordinates the program
clear_screen prepares the display
print draws the message
data controls the colours and text
```

The routines are not perfect abstractions yet.

They use shared memory locations as inputs.

That is deliberate.

At this stage, the goal is to make subroutine inputs and side effects visible, not to hide them behind a calling convention too early.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/10-clear-screen-and-coloured-text
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
ASSEMBLY FROM SCRATCH
```

on a clean screen.

After the program runs, it returns to BASIC.

## Machine concepts

This lesson introduces:

- Screen initialisation
- Clearing screen memory with spaces
- Initialising colour RAM
- Printing coloured text
- Program structure with multiple routines
- Routine inputs stored in named memory locations
- Routine side effects and destroyed registers

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- Zero-page pointers
- Screen memory
- Colour RAM
- Zero-terminated text
- C64 screen-code encoding

## Assembly concepts

This lesson introduces or reinforces:

- Multiple subroutines
- `jsr` and `rts`
- `(pointer),y` for screen and colour output
- Zero-page pointer setup
- Named data bytes as routine inputs
- Register side effects

It reuses:

- `lda`
- `sta`
- `ldx`
- `ldy`
- `inx`
- `iny`
- `bne`
- `beq`
- `jmp`
- `.text`
- `.byte`
- `.const`
- `<` and `>` address-byte extraction

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$fb-$fc` | `message_ptr` zero-page pointer |
| `$fd-$fe` | `screen_ptr` zero-page pointer |
| `$02-$03` | `colour_ptr` zero-page pointer |
| `$0400-$07ff` | Screen memory pages cleared by `clear_screen` |
| `$d800-$dbff` | Colour RAM pages initialised by `clear_screen` |
| `$0428` | Message screen position, row 1, column 0 |
| `$d828` | Message colour RAM position, row 1, column 0 |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the message

Change:

```asm
.text "ASSEMBLY FROM SCRATCH"
```

to another message.

Build and run again.

### Change the text colour

Change:

```asm
lda #$01
sta text_colour
```

to another colour value.

For example:

```asm
lda #$03
sta text_colour
```

Build and run again.

### Change the clear colour

Change:

```asm
clear_colour:
    .byte $06
```

to another colour value.

Build and run again.

The border, background, and cleared colour RAM should use the new colour.

### Move the message

Change:

```asm
lda #<$0428
lda #>$0428
```

and:

```asm
lda #<$d828
lda #>$d828
```

to another matching screen and colour RAM position.

For example:

```asm
$0450
$d850
```

Build and run again.

### Remove the clear screen call

Comment out:

```asm
jsr clear_screen
```

Build and run again.

The message should still print, but the screen may contain whatever was already there.

This shows why display initialisation matters.

### Change `clear_screen` to use one colour for RAM only

Set border and background separately, then use `clear_colour` only for colour RAM.

This is a good experiment if you want to separate display background from cell colour.

## Common mistakes

### Thinking these are local function parameters

They are not.

`message_ptr`, `screen_ptr`, `colour_ptr`, `clear_colour`, and `text_colour` are shared memory locations.

The routines read them as inputs.

### Forgetting which registers routines destroy

`clear_screen` destroys A and X.

`print` destroys A and Y.

Later lessons will introduce preserving registers when needed.

### Forgetting colour RAM must match screen position

If the message is printed at `$0428`, the matching colour RAM address is `$d828`.

If these do not match, the text may appear with unexpected colours.

### Using `$00-$01` for zero-page pointers

Do not use `$00-$01` casually on the C64.

They are special and related to the 6510's I/O port and memory banking.

### Thinking 1024 bytes is exactly the visible screen

The visible screen is 1000 cells.

The clear routine fills 1024 bytes because it clears four full pages.

That is deliberately simple for this lesson.

## What comes next

Next lesson:

```text
11 - Calling conventions and register preservation
```

We have now started using subroutines with inputs and side effects.

The next natural step is to make that explicit:

- what routines expect
- what routines destroy
- when to preserve registers
- how `pha` and `pla` work
- how the stack can help
- why 6502 calling conventions are a design choice rather than a built-in system

This will help make function-style assembly code cleaner without hiding the machine.
