# Lesson 09 - Text subroutine

## Goal

Use a reusable subroutine to print zero-terminated text at different screen positions.

In Lesson 08, one loop copied one message to one fixed position.

In this lesson, the copy logic becomes a reusable routine.

The program sets up pointers, calls the routine with `jsr`, and the routine returns with `rts`.

## What you will build

You will build a small C64 program that prints three messages:

```text
ASSEMBLY
FROM
SCRATCH
```

The messages are printed on three different rows.

The important part is that the same print routine is used for all three messages.

## What this teaches

This lesson introduces:

- `jsr` - jump to subroutine
- `rts` - return from subroutine
- zero-page pointers
- little-endian pointer storage
- `<` and `>` for low and high address bytes
- indirect indexed addressing with `(pointer),y`

The key idea is:

```text
The print routine does not know which message it prints.
It reads the address from message_ptr.

The print routine does not know where the message appears.
It reads the destination from screen_ptr.
```

That makes the routine reusable.

## Files

This lesson contains:

```text
platforms/c64/lessons/09-text-subroutine/
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
// Lesson 09: Text subroutine
//
// This lesson introduces subroutines and zero-page pointers.
//
// In the previous lesson, one loop copied one zero-terminated message
// to one fixed screen position.
//
// In this lesson, we write one reusable print routine.
//
// The routine can print different messages at different screen positions.
//
// To do that, it uses two zero-page pointers:
//
//   message_ptr - where the message starts
//   screen_ptr  - where the text should appear
//
// The print routine reads a zero-terminated message and copies it to the screen.

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
//
// The indirect indexed addressing mode:
//
//   (pointer),y
//
// requires the pointer to live in zero page.

.const message_ptr = $fb
.const screen_ptr  = $fd

// -----------------------------------------------------------------------------
// Machine code
// -----------------------------------------------------------------------------

* = $080d

.encoding "screencode_upper"  // Convert .text strings to C64 uppercase screen codes

start:
    lda #$06                  // Load colour value $06, blue
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

// -----------------------------------------------------------------------------
// Pointer setup
// -----------------------------------------------------------------------------
//
// A C64 address is 16 bits, so a pointer needs two bytes.
//
// The 6510 stores 16-bit addresses in little-endian order:
//
//   low byte first
//   high byte second
//
// KickAssembler's < and > operators extract those bytes:
//
//   <address = low byte
//   >address = high byte
//
// The C64 screen is 40 columns wide:
//
//   $0400 = row 0, column 0
//   $0428 = row 1, column 0 ($0400 + 40)
//   $0450 = row 2, column 0 ($0400 + 80)

    lda #<message_assembly    // Load low byte of message_assembly address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message_assembly    // Load high byte of message_assembly address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0400               // Load low byte of screen address $0400
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0400               // Load high byte of screen address $0400
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    jsr print                 // Print message_assembly at $0400

    lda #<message_from        // Load low byte of message_from address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message_from        // Load high byte of message_from address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0428               // Load low byte of screen address $0428
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0428               // Load high byte of screen address $0428
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    jsr print                 // Print message_from at $0428

    lda #<message_scratch     // Load low byte of message_scratch address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message_scratch     // Load high byte of message_scratch address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0450               // Load low byte of screen address $0450
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0450               // Load high byte of screen address $0450
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    jsr print                 // Print message_scratch at $0450

    rts                       // Return to BASIC

// -----------------------------------------------------------------------------
// Print subroutine
// -----------------------------------------------------------------------------
//
// Prints a zero-terminated message to screen memory.
//
// Input:
//
//   message_ptr - address of the zero-terminated message
//   screen_ptr  - address where the message should appear
//
// Uses:
//
//   A - current character
//   Y - offset into the message and screen position

print:
    ldy #$00                  // Start Y at zero

copy:
    lda (message_ptr),y       // Load one byte from message_ptr + Y
    beq done                  // If the byte is zero, the message is finished

    sta (screen_ptr),y        // Store the byte at screen_ptr + Y

    iny                       // Move to the next character
    jmp copy                  // Continue copying

done:
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Message data
// -----------------------------------------------------------------------------

message_assembly:
    .text "ASSEMBLY"
    .byte 0

message_from:
    .text "FROM"
    .byte 0

message_scratch:
    .text "SCRATCH"
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
```

These are KickAssembler constants.

They name zero-page addresses.

`message_ptr` uses two bytes:

```text
$fb-$fc
```

`screen_ptr` also uses two bytes:

```text
$fd-$fe
```

Each pointer needs two bytes because a C64 address is 16 bits.

The `.const` syntax is KickAssembler-specific. A line such as:

```asm
message_ptr = $fb
```

may work in other assemblers, but not here.

For KickAssembler, use:

```asm
.const message_ptr = $fb
```

### Why zero page?

Zero page is the first 256 bytes of memory:

```text
$0000-$00ff
```

The 6510 has special addressing modes that use pointers stored in zero page.

This instruction:

```asm
lda (message_ptr),y
```

requires `message_ptr` to be a zero-page address.

The pointer itself lives in zero page.

The data it points to can live elsewhere.

That is why we put the pointer bytes at `$fb-$fc` and `$fd-$fe`.

### Machine-code start and encoding

```asm
* = $080d

.encoding "screencode_upper"
```

The machine code starts at `$080d`, matching the BASIC loader's `SYS 2061`.

The `.encoding` directive tells KickAssembler to convert `.text` strings into C64 uppercase screen codes.

### Set border and background colour

```asm
lda #$06
sta $d020
sta $d021
```

This sets both border and background to blue.

The accumulator still contains `$06` after the first store, so the same value can be stored again without another `lda`.

### Pointers are two bytes

A C64 address is 16 bits.

That means a pointer needs two bytes.

The 6510 stores 16-bit addresses in little-endian order:

```text
low byte first
high byte second
```

So a pointer is stored like this:

```text
pointer     = low byte
pointer + 1 = high byte
```

For example:

```asm
lda #<message_assembly
sta message_ptr

lda #>message_assembly
sta message_ptr + 1
```

This stores the address of `message_assembly` into `message_ptr`.

### The `<` and `>` operators

KickAssembler's `<` and `>` operators extract the low and high bytes of an address:

```asm
#<message_assembly
#>message_assembly
```

If `message_assembly` were located at `$0860`, then:

```text
#<message_assembly = $60
#>message_assembly = $08
```

These operators are assembler features.

They are not CPU instructions.

The assembler calculates the bytes while building the program.

### Screen row addresses

The C64 character screen is 40 columns wide.

So moving down one row means adding 40 bytes.

The lesson uses:

| Screen address | Position |
|---|---|
| `$0400` | row 0, column 0 |
| `$0428` | row 1, column 0 |
| `$0450` | row 2, column 0 |

Why?

```text
$0428 = $0400 + 40
$0450 = $0400 + 80
```

The program prints each message at one of these addresses.

### Setting up the first message

```asm
lda #<message_assembly
sta message_ptr
lda #>message_assembly
sta message_ptr + 1

lda #<$0400
sta screen_ptr
lda #>$0400
sta screen_ptr + 1

jsr print
```

This does three things:

1. Stores the address of `message_assembly` into `message_ptr`
2. Stores the screen address `$0400` into `screen_ptr`
3. Calls the `print` subroutine

### Calling a subroutine

```asm
jsr print
```

`jsr` means:

```text
Jump to SubRoutine
```

It jumps to the label `print`.

It also saves a return address on the stack so that `rts` can return to the instruction after the `jsr`.

So:

```asm
jsr print
```

means:

```text
Go run the print routine, then come back here when it returns
```

### The print subroutine

```asm
print:
    ldy #$00

copy:
    lda (message_ptr),y
    beq done

    sta (screen_ptr),y

    iny
    jmp copy

done:
    rts
```

This is the reusable routine.

It does not contain a hard-coded message address.

It does not contain a hard-coded screen address.

Instead, it uses the two pointers.

### Y as the offset

```asm
ldy #$00
```

Y starts at zero.

It is used as the offset into both the message and the screen destination.

So:

```text
Y = 0 -> first character
Y = 1 -> second character
Y = 2 -> third character
```

### Loading through a pointer

```asm
lda (message_ptr),y
```

This is indirect indexed addressing.

It means:

```text
1. Read the 16-bit address stored in message_ptr
2. Add Y
3. Load the byte from that final address
```

So if `message_ptr` contains the address of `message_assembly`, then:

```asm
lda (message_ptr),y
```

loads from:

```text
message_assembly + Y
```

### Checking for the zero terminator

```asm
beq done
```

`lda` updates the zero flag.

If the loaded byte is zero, the message has ended.

Then `beq done` branches to `done`.

### Storing through a pointer

```asm
sta (screen_ptr),y
```

This stores the accumulator at:

```text
address stored in screen_ptr + Y
```

So if `screen_ptr` contains `$0400`, the first message is written at:

```text
$0400 + Y
```

If `screen_ptr` contains `$0428`, the next message is written at:

```text
$0428 + Y
```

Same routine.

Different destination.

### Returning from the subroutine

```asm
rts
```

Inside `print`, `rts` returns to the instruction after the most recent `jsr print`.

At the end of `start`, another `rts` returns to BASIC.

The same instruction is used in both places, but the return target is different because the call stack is different.

### Message data

```asm
message_assembly:
    .text "ASSEMBLY"
    .byte 0

message_from:
    .text "FROM"
    .byte 0

message_scratch:
    .text "SCRATCH"
    .byte 0
```

Each message is zero-terminated.

The print routine copies bytes until it finds the zero byte.

## The key idea

Lesson 08 had fixed code:

```asm
lda message,x
sta $0400,x
```

Lesson 09 replaces fixed addresses with pointers:

```asm
lda (message_ptr),y
sta (screen_ptr),y
```

That makes the print routine reusable.

The main program changes the pointers.

The subroutine stays the same.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/09-text-subroutine
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
ASSEMBLY
FROM
SCRATCH
```

on three different rows.

After the program runs, it returns to BASIC.

## Machine concepts

This lesson introduces:

- Zero-page pointers
- The stack behaviour behind `jsr` and `rts`
- Reusable routines
- Text output at different screen positions
- 40-byte screen rows

It reuses:

- BASIC loader at `$0801`
- Machine code start at `$080d`
- Screen memory at `$0400`
- Zero-terminated text
- C64 screen-code encoding

## Assembly concepts

This lesson introduces:

- `.const`
- `jsr`
- indirect indexed addressing with `(pointer),y`
- `<` and `>` address-byte extraction
- little-endian pointer setup
- reusable subroutines

It reuses:

- `lda`
- `sta`
- `ldy`
- `iny`
- `jmp`
- `beq`
- `rts`
- `.text`
- `.byte`
- labels

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$fb-$fc` | `message_ptr` zero-page pointer |
| `$fd-$fe` | `screen_ptr` zero-page pointer |
| `$0400` | Row 0, column 0 |
| `$0428` | Row 1, column 0 |
| `$0450` | Row 2, column 0 |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change a message

Change:

```asm
.text "ASSEMBLY"
```

to:

```asm
.text "COMMODORE"
```

Build and run again.

The print routine should still work.

### Change a screen position

Change the destination for `message_from` from:

```asm
lda #<$0428
lda #>$0428
```

to:

```asm
lda #<$0478
lda #>$0478
```

Build and run again.

The message should move to a lower row.

### Remove one `jsr print`

Remove one call to:

```asm
jsr print
```

Build and run again.

That message should no longer appear.

### Break the low byte deliberately

For one message, change:

```asm
lda #<message_from
```

to use another message's low byte.

Build and observe what happens.

Put it back afterwards.

This helps show that both pointer bytes matter.

### Change the zero-page pointer locations

Do not use `$00` or `$01`.

For example, try moving the pointers to another safe area only after checking a C64 zero-page map.

This experiment is optional.

## Common mistakes

### Forgetting `.const`

In KickAssembler, write:

```asm
.const message_ptr = $fb
```

not:

```asm
message_ptr = $fb
```

### Forgetting that a pointer needs two bytes

A C64 address is 16 bits.

This is not enough:

```asm
sta message_ptr
```

You must also store the high byte:

```asm
sta message_ptr + 1
```

### Reversing low and high bytes

The 6510 uses little-endian order:

```text
low byte first
high byte second
```

So use:

```asm
lda #<address
sta pointer

lda #>address
sta pointer + 1
```

### Thinking `(pointer),y` can use any pointer address

It cannot.

The pointer itself must live in zero page.

That is why we use `$fb-$fe`.

### Confusing `jsr` and `jmp`

`jmp print` would jump to the routine but would not save a return address.

`jsr print` calls the routine and lets `rts` return.

### Forgetting that colour RAM is not handled here

This lesson prints characters only.

It does not set per-character colour RAM.

That is intentional.

The lesson focuses on subroutines and pointers.

## What comes next

Next lesson:

```text
10 - Text colour subroutine
```

Now that the text routine can print messages at different screen positions, the next step is to extend the idea carefully.

Possible next steps:

- add a colour pointer
- add a fixed colour value
- print text with colour
- avoid overloading the first subroutine lesson

The important thing is that the subroutine and pointer model is now grounded.
