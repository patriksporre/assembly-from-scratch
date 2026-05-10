# Lesson 24 - Chained raster interrupts

## Goal

Create the first interrupt-driven raster band.

Lesson 23 used one raster interrupt:

```text
line 100 -> change border colour
```

This lesson uses two raster interrupts:

```text
line 100 -> set border and background to blue
line 120 -> set border and background back to black
```

Each interrupt handler sets up the next interrupt.

That means the interrupt chain alternates between two handlers:

```text
irq_top -> irq_bottom -> irq_top -> irq_bottom
```

## What you will build

You will build a C64 program that creates a horizontal colour band using chained raster interrupts.

The main program does almost nothing:

```asm
main_loop:
    jmp main_loop
```

The visible band is created by the VIC-II interrupting the CPU at two different raster lines.

At line 100, the interrupt handler sets the border and background to blue.

At line 120, the interrupt handler sets them back to black.

## What this teaches

This lesson teaches:

- how to chain raster interrupts
- how one interrupt handler can install the next handler
- how one interrupt handler can change the next raster line
- how to create a simple interrupt-driven raster band
- why timing-critical colour writes should happen early in the handler
- why saving A before using it still matters
- why chained interrupts are structured but not automatically stable

The key structure is:

```text
first IRQ -> visible change -> set next IRQ
second IRQ -> visible change -> set first IRQ again
```

## Important timing note

This lesson improves the handler layout by moving the visible colour write early.

The handler saves A first:

```asm
pha
```

Then it writes the colours:

```asm
lda #$06
sta $d020
sta $d021
```

Only after that does it save X and Y and set up the next interrupt.

This reduces the delay before the visible colour change.

However, this is still not cycle-stable raster timing.

The first affected line may still start part-way across the screen, and some flicker may remain.

That is expected.

This lesson proves chaining.

It does not yet solve stable raster timing.

## Important interrupt note

This lesson uses:

```asm
sei
```

during setup and:

```asm
cli
```

after setup.

It disables CIA interrupts and uses the VIC-II raster interrupt as the only intended IRQ source.

The program banks out BASIC and KERNAL ROM so it can write the hardware IRQ vector at `$fffe/$ffff`.

This is a controlled machine-code lesson, not a BASIC-friendly program.

Reset the emulator to stop it.

## Files

This lesson contains:

```text
platforms/c64/lessons/24-chained-raster-interrupts/
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
// Lesson 24: Chained raster interrupts
//
// This lesson introduces chained raster interrupts.
//
// Lesson 23 used one raster interrupt:
//
//   line 100 -> change border colour
//
// This lesson uses two raster interrupts:
//
//   line 100 -> set border and background colour to blue
//   line 120 -> set border and background colour back to black
//
// Each interrupt handler sets up the next interrupt.
//
// This creates our first interrupt-driven raster band.
//
// This is not yet cycle-stable raster timing.
// Some flicker or partial-line transition may still be visible.
// The goal of this lesson is interrupt chaining.

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
    sei                       // Disable IRQs while we change interrupt setup

    lda #$35                  // Keep I/O visible, but bank out BASIC and KERNAL ROM
    sta $01                   // This lets us write the hardware IRQ vector at $fffe/$ffff

    lda #$00                  // Load colour 0, black
    sta $d020                 // Set border colour to black
    sta $d021                 // Set background colour to black

    lda #%01111111            // Disable all CIA #1 interrupt sources
    sta $dc0d                 // Write interrupt mask to CIA #1 interrupt control register

    lda #%01111111            // Disable all CIA #2 interrupt sources
    sta $dd0d                 // Write interrupt mask to CIA #2 interrupt control register

    lda $dc0d                 // Acknowledge any pending CIA #1 interrupt
    lda $dd0d                 // Acknowledge any pending CIA #2 interrupt

    lda #<irq_top             // Load low byte of first IRQ handler address
    sta $fffe                 // Store low byte in hardware IRQ vector

    lda #>irq_top             // Load high byte of first IRQ handler address
    sta $ffff                 // Store high byte in hardware IRQ vector

    lda #100                  // First raster interrupt line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because line 100 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Clear any pending VIC-II raster interrupt

    lda #%00000001            // Bit 0 enables VIC-II raster interrupts
    sta $d01a                 // Enable raster interrupt source

    cli                       // Enable IRQs again

main_loop:
    jmp main_loop             // Do nothing. Raster interrupts run independently

// -----------------------------------------------------------------------------
// IRQ top handler
// -----------------------------------------------------------------------------
//
// Runs when the raster reaches line 100.
//
// This handler:
//   saves A
//   sets the border and background colour to blue
//   saves X and Y
//   sets the next interrupt handler to irq_bottom
//   sets the next raster line to 120
//   acknowledges the VIC-II interrupt
//   restores Y, X, and A
//   returns with rti
//
// A is saved before the colour write because loading the colour changes A.
// The colour write is placed early because it is timing-critical.
//
// Input:
//
//   none
//
// Output:
//
//   border and background colour changed to blue
//   next raster interrupt set to line 120 and irq_bottom
//
// Destroys:
//
//   none, after restoration
//
// Preserves:
//
//   A
//   X
//   Y
//   flags are restored by rti
//
// Memory used:
//
//   stack page $0100-$01ff

irq_top:
    pha                       // Save A before using it

    lda #$06                  // Load colour 6, blue
    sta $d020                 // Set border colour to blue
    sta $d021                 // Set background colour to blue

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    lda #<irq_bottom          // Load low byte of next IRQ handler
    sta $fffe                 // Store low byte in IRQ vector

    lda #>irq_bottom          // Load high byte of next IRQ handler
    sta $ffff                 // Store high byte in IRQ vector

    lda #120                  // Next raster interrupt line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 120 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the VIC-II interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt

// -----------------------------------------------------------------------------
// IRQ bottom handler
// -----------------------------------------------------------------------------
//
// Runs when the raster reaches line 120.
//
// This handler:
//   saves A
//   sets the border and background colour back to black
//   saves X and Y
//   sets the next interrupt handler to irq_top
//   sets the next raster line to 100
//   acknowledges the VIC-II interrupt
//   restores Y, X, and A
//   returns with rti
//
// Input:
//
//   none
//
// Output:
//
//   border and background colour changed to black
//   next raster interrupt set to line 100 and irq_top
//
// Destroys:
//
//   none, after restoration
//
// Preserves:
//
//   A
//   X
//   Y
//   flags are restored by rti
//
// Memory used:
//
//   stack page $0100-$01ff

irq_bottom:
    pha                       // Save A before using it

    lda #$00                  // Load colour 0, black
    sta $d020                 // Set border colour to black
    sta $d021                 // Set background colour to black

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    lda #<irq_top             // Load low byte of next IRQ handler
    sta $fffe                 // Store low byte in IRQ vector

    lda #>irq_top             // Load high byte of next IRQ handler
    sta $ffff                 // Store high byte in IRQ vector

    lda #100                  // Next raster interrupt line
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 100 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the VIC-II interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt
```

## Code walkthrough

### BASIC loader

The BASIC loader creates:

```basic
10 SYS 2061
```

When you type `RUN`, BASIC starts the machine code at `$080d`.

### Initial interrupt setup

The setup is similar to Lesson 23.

The program:

```text
disables IRQs
banks out BASIC and KERNAL ROM
disables CIA interrupt sources
installs the first IRQ handler
sets the first raster line
enables VIC-II raster interrupts
enables CPU IRQ handling again
```

The first handler is `irq_top`.

The first raster line is 100:

```asm
lda #<irq_top
sta $fffe

lda #>irq_top
sta $ffff

lda #100
sta $d012
```

### Main loop

The main loop does nothing:

```asm
main_loop:
    jmp main_loop
```

The visible output is driven by the raster interrupts.

### Top interrupt

`irq_top` runs at raster line 100.

It first saves A:

```asm
pha
```

Then it performs the timing-critical visible work:

```asm
lda #$06
sta $d020
sta $d021
```

This sets the border and background to blue.

Then it saves X and Y:

```asm
txa
pha

tya
pha
```

Then it installs `irq_bottom` as the next handler and line 120 as the next interrupt line:

```asm
lda #<irq_bottom
sta $fffe

lda #>irq_bottom
sta $ffff

lda #120
sta $d012
```

Finally it acknowledges the VIC-II interrupt, restores registers, and returns with `rti`.

### Bottom interrupt

`irq_bottom` runs at raster line 120.

It follows the same structure, but sets the colours back to black:

```asm
lda #$00
sta $d020
sta $d021
```

Then it installs `irq_top` as the next handler and line 100 as the next interrupt line.

So the chain loops forever:

```text
line 100 -> irq_top -> line 120 -> irq_bottom -> line 100 -> irq_top
```

## Why the colour write moved earlier

In Lesson 23, the handler saved A, X, and Y before doing the visible work.

That is safe, but it delays the colour write.

In this lesson, the handler saves A first, then writes the colour:

```asm
pha

lda #$06
sta $d020
sta $d021
```

This keeps A safe while moving the visible write earlier.

X and Y are saved afterwards because the colour write does not need them.

This is a real C64 design trade-off:

```text
do timing-critical visible work early
still preserve registers correctly
do setup work afterwards
```

## Why flicker can remain

This lesson chains raster interrupts, but it does not stabilise them.

A raster interrupt does not mean the colour write happens at the exact same pixel every frame.

There is still timing variation from:

```text
the CPU instruction being interrupted
interrupt entry overhead
handler instruction timing
VIC-II cycle stealing
writing $d020 and $d021 on different cycles
```

So the band may still flicker or begin part-way across the screen.

That is expected.

This lesson proves chaining.

Lesson 25 will focus on stability.

## The key idea

Lesson 24 introduces chained raster interrupts.

One interrupt sets up the next interrupt.

That lets us describe screen events as a sequence:

```text
line 100 - turn colour on
line 120 - turn colour off
```

This is the foundation for:

```text
raster bands
raster bars
split screens
music timing
multiple screen zones
later anonymous IRQ-style structures
```

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/24-chained-raster-interrupts
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

You should see a horizontal blue band.

The band begins around raster line 100 and ends around raster line 120.

Some flicker or partial-line transition may remain.

## Machine concepts

This lesson introduces:

- chained raster interrupts
- changing the IRQ vector inside an interrupt handler
- changing the next raster line inside an interrupt handler
- interrupt-driven raster bands
- early timing-critical colour writes
- the difference between interrupt structure and interrupt stability

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- C64 memory configuration through `$01`
- hardware IRQ vector at `$fffe/$ffff`
- VIC-II raster target through `$d012`
- high raster bit in `$d011`
- VIC-II interrupt acknowledge through `$d019`
- VIC-II interrupt enable through `$d01a`
- border colour through `$d020`
- background colour through `$d021`
- disabling CIA interrupts through `$dc0d` and `$dd0d`
- `sei`
- `cli`
- `rti`
- register preservation
- stack page `$0100-$01ff`

## Assembly concepts

This lesson introduces or reinforces:

- handler chaining
- changing code flow by changing vectors
- preserving A before timing-critical work
- installing a new IRQ handler inside the current handler
- setting a new raster target inside the current handler
- visible timing as a design constraint

It reuses:

- `lda`
- `sta`
- `and`
- `pha`
- `pla`
- `txa`
- `tax`
- `tya`
- `tay`
- `jmp`
- `.word`
- `.byte`
- `.text`
- `<` for low byte
- `>` for high byte

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0001` | C64 processor port, memory configuration |
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$0100-$01ff` | Stack page used by CPU and handler saves |
| `$d011` | VIC-II control register 1, includes high raster bit |
| `$d012` | VIC-II raster line low byte and raster interrupt target |
| `$d019` | VIC-II interrupt status/acknowledge register |
| `$d01a` | VIC-II interrupt enable register |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |
| `$dc0d` | CIA #1 interrupt control/status register |
| `$dd0d` | CIA #2 interrupt control/status register |
| `$fffe` | Hardware IRQ vector low byte |
| `$ffff` | Hardware IRQ vector high byte |

## Experiments

### Move the band

Change the two raster lines:

```asm
lda #100
sta $d012
```

and:

```asm
lda #120
sta $d012
```

Try 80 and 110.

The band should move upward and become taller.

### Make the band taller

Keep the first line at 100 and change the second line:

```asm
lda #140
sta $d012
```

The blue band should become taller.

### Use border only

Temporarily remove:

```asm
sta $d021
```

from both handlers.

The effect should return to a border-only raster band.

Put it back afterwards.

### Change the colours

Change:

```asm
lda #$06
```

to another colour value.

Try red:

```asm
lda #$02
```

or yellow:

```asm
lda #$07
```

### Move the colour write later

Move the colour write after the X/Y saves.

Observe that the visible transition starts later.

Then move it back.

## Common mistakes

### Expecting perfect stability

This lesson is about chaining, not stable timing.

Flicker can remain.

### Forgetting to set the next handler

If `irq_top` does not install `irq_bottom`, the second interrupt will not happen correctly.

If `irq_bottom` does not install `irq_top`, the chain will not continue.

### Forgetting to acknowledge the interrupt

The VIC-II interrupt must be acknowledged with:

```asm
lda #%00000001
sta $d019
```

### Using `rts` instead of `rti`

Interrupt handlers return with `rti`.

### Saving A too late

If the handler changes A before saving it, the interrupted program may not get A back correctly.

That is why the handler begins with `pha`.

## What comes next

Next lesson:

```text
25 - Stable raster interrupt timing
```

Lesson 24 proved that one interrupt can set up the next interrupt.

But the visible transition can still flicker.

Lesson 25 will focus on the next question:

```text
How do we make the colour write land at a predictable horizontal position?
```

That is the missing piece between chained raster interrupts and proper raster bars.
