# Lesson 25 - Stable raster interrupt timing

## Goal

Improve the chained raster interrupt from Lesson 24 by reducing visible timing jitter.

Lesson 24 created an interrupt-driven raster band:

```text
line 100 - colour on
line 120 - colour off
```

But the visible transition could still flicker.

Lesson 25 introduces a simple stabilising idea:

```text
trigger the interrupt slightly before the visible change
wait inside the handler for known raster line transitions
then write the colour
```

This is not the final cycle-perfect raster technique.

It is the first deliberate step toward stable raster interrupt timing.

## What you will build

You will build a C64 program with two chained raster interrupts.

The first interrupt triggers one line before the intended blue change.

The second interrupt triggers one line before the intended black change.

Inside each handler, the code waits for the next raster lines before writing the colour.

This gives the colour write a more repeatable position than Lesson 24.

The result should be a much more stable full-screen blue band.

Small edge artefacts may remain.

## What this teaches

This lesson teaches:

- that a raster interrupt gives us a line, but not a perfectly stable cycle inside that line
- why IRQ entry timing can still produce visible jitter
- how to trigger an interrupt early and wait inside the handler
- how a handler can use `$d012` after the interrupt has fired
- why stability improves when visible writes happen after controlled waits
- why `$d020` and `$d021` can still show edge artefacts
- why proper raster bars require even more cycle control later

The key structure is:

```text
IRQ fires early -> wait for target lines -> write colour -> set next IRQ
```

## Important timing note

A raster interrupt does not mean the colour write happens at the exact same pixel every frame.

When the VIC-II requests the interrupt, the CPU may be in the middle of different instructions.

The CPU must finish the current instruction, enter the interrupt, push return state, jump through the IRQ vector, and start executing the handler.

That means the handler can begin with small timing variation.

Lesson 25 reduces this by triggering the interrupt one line early and waiting inside the handler before writing the colour.

This improves stability, but it is still not fully cycle-perfect.

## Remaining artefacts

You may still see small artefacts at the edges of the colour band.

That is expected.

There are two main reasons:

```text
$d020 and $d021 are written on different cycles
the code is not yet fully cycle-stabilised
```

The border and background colour cannot change at exactly the same CPU cycle with these instructions:

```asm
sta $d020
sta $d021
```

The VIC-II continues drawing while the CPU executes those writes.

So small edge differences can remain.

Lesson 25 should be judged against Lesson 24:

```text
Lesson 24 - chained, but visibly unstable
Lesson 25 - much more stable, but not yet perfect
```

That is the intended result.

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

It disables CIA interrupts and uses the VIC-II raster interrupt as the intended IRQ source.

The program banks out BASIC and KERNAL ROM so it can write the hardware IRQ vector at `$fffe/$ffff`.

This is a controlled machine-code lesson, not a BASIC-friendly program.

Reset the emulator to stop it.

## Files

This lesson contains:

```text
platforms/c64/lessons/25-stable-raster-interrupt-timing/
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
// Lesson 25: Stable raster interrupt timing
//
// This lesson improves the chained raster interrupt from Lesson 24.
//
// Lesson 24 created an interrupt-driven raster band:
//
//   line 100 -> colour on
//   line 120 -> colour off
//
// But the visible colour transition could still flicker.
// A raster interrupt gives us a raster line, but not an exact cycle inside
// that line.
//
// This lesson introduces a simple stabilising idea:
//
//   trigger the IRQ slightly before the visible change
//   wait inside the handler for the next line boundary
//   then write the colour
//
// This is still not the final elite stable raster technique,
// but it is the first deliberate step toward stable raster interrupts.

// -----------------------------------------------------------------------------
// BASIC loader
// -----------------------------------------------------------------------------

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

    lda #99                   // Trigger one line before the visible blue change
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear raster high bit because line 99 is below 256
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

irq_top:
    pha                       // Save A before using it

wait_top_line_100:
    lda $d012                 // Read current raster line
    cmp #100                  // Wait until line 100 is reached
    bne wait_top_line_100     // Keep waiting until raster line is 100

wait_top_line_101:
    lda $d012                 // Read current raster line
    cmp #101                  // Wait until line 101 is reached
    bne wait_top_line_101     // Keep waiting until raster line is 101

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

    lda #119                  // Trigger one line before the visible black change
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 119 is below 256
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

irq_bottom:
    pha                       // Save A before using it

wait_bottom_line_120:
    lda $d012                 // Read current raster line
    cmp #120                  // Wait until line 120 is reached
    bne wait_bottom_line_120  // Keep waiting until raster line is 120

wait_bottom_line_121:
    lda $d012                 // Read current raster line
    cmp #121                  // Wait until line 121 is reached
    bne wait_bottom_line_121  // Keep waiting until raster line is 121

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

    lda #99                   // Trigger one line before the visible blue change
    sta $d012                 // Store low 8 bits of raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear high raster bit because line 99 is below 256
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

### Initial setup

The setup is similar to Lesson 24.

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

The first raster line is now 99:

```asm
lda #<irq_top
sta $fffe

lda #>irq_top
sta $ffff

lda #99
sta $d012
```

Line 99 is one line before the intended visible blue change.

### Main loop

The main loop does nothing:

```asm
main_loop:
    jmp main_loop
```

The visible output is driven by the raster interrupts.

### Top interrupt

`irq_top` runs when the raster reaches line 99.

It saves A first:

```asm
pha
```

Then it waits for line 100:

```asm
wait_top_line_100:
    lda $d012
    cmp #100
    bne wait_top_line_100
```

Then it waits for line 101:

```asm
wait_top_line_101:
    lda $d012
    cmp #101
    bne wait_top_line_101
```

Then it writes the visible colour:

```asm
lda #$06
sta $d020
sta $d021
```

After that, it saves X and Y, installs the next handler, sets the next raster line, acknowledges the interrupt, restores registers, and returns with `rti`.

### Bottom interrupt

`irq_bottom` follows the same pattern.

It runs at line 119, waits for line 120, waits for line 121, then writes black:

```asm
lda #$00
sta $d020
sta $d021
```

Then it installs `irq_top` again and sets the next raster line to 99.

So the chain is still:

```text
irq_top -> irq_bottom -> irq_top -> irq_bottom
```

but each handler now waits inside itself before the visible write.

## Why this is more stable

Lesson 24 did this:

```text
IRQ fires
handler writes colour early
```

Lesson 25 does this:

```text
IRQ fires early
handler waits for known raster lines
handler writes colour
```

That means the handler no longer depends only on when the CPU entered the IRQ.

It uses the raster counter inside the handler to reduce visible entry jitter.

This gives a more stable result.

## Why it is still not perfect

The remaining edge artefacts are expected.

The code still writes two registers sequentially:

```asm
sta $d020
sta $d021
```

They cannot change at exactly the same cycle.

Also, this is not yet a fully cycle-perfect stable IRQ.

We have improved timing, but not completely controlled every cycle.

That comes later.

## The visible result

You should see a blue full-screen band.

Compared with Lesson 24, the band should be much more stable.

You may still see small artefacts at the left or right edge where the border and background transition do not perfectly align.

This is expected and useful.

It shows the next level of timing precision we have not solved yet.

## The key idea

A raster interrupt gives us a screen line.

Stable raster effects also need control over timing inside that line.

Lesson 25 introduces the idea that an IRQ handler can perform its own raster waits before doing visible work.

This is a bridge from simple chained interrupts to proper raster bars.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/25-stable-raster-interrupt-timing
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

You should see a stable blue full-screen band.

## Machine concepts

This lesson introduces:

- stable raster interrupt timing as a separate concern from raster interrupt chaining
- triggering an IRQ before the visible change
- waiting inside an IRQ handler using `$d012`
- reducing IRQ entry jitter
- remaining edge artefacts from sequential register writes
- the idea that full stability requires cycle control

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

- waiting inside an interrupt handler
- using an early IRQ as a setup point
- reducing visible jitter through controlled waits
- distinguishing structural correctness from timing stability
- preserving registers while doing timing-sensitive work

It reuses:

- `lda`
- `sta`
- `cmp`
- `bne`
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

### Compare with Lesson 24

Run Lesson 24.

Then run Lesson 25.

Look at the start and end of the blue band.

Lesson 25 should be more stable.

### Change the visible band position

Change the interrupt setup lines and the internal waits together.

For example, move the blue start down by 20 lines:

```text
irq_top trigger: 119
wait for: 120 and 121
```

and move the black end down by the same amount:

```text
irq_bottom trigger: 139
wait for: 140 and 141
```

### Use border only

Temporarily remove:

```asm
sta $d021
```

from both handlers.

This makes it easier to observe the border timing alone.

Put it back afterwards.

### Change the colour

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

### Remove one internal wait

Remove the second wait in `irq_top` or `irq_bottom`.

Observe whether stability changes.

Put it back afterwards.

## Common mistakes

### Expecting perfection

This lesson improves stability.

It does not create perfect raster bars yet.

### Forgetting that the IRQ now fires early

The interrupt target line is not the same as the visible colour line.

The IRQ fires at line 99 so the visible change can happen after internal waits.

### Changing only one line number

If you move the band, remember that the IRQ trigger line and the internal wait lines belong together.

### Forgetting to acknowledge the interrupt

The VIC-II interrupt must be acknowledged with:

```asm
lda #%00000001
sta $d019
```

### Using `rts` instead of `rti`

Interrupt handlers return with `rti`.

## What comes next

Next lesson:

```text
26 - Proper raster bars
```

Lesson 25 made the interrupt-driven band more stable.

Lesson 26 can now use this improved structure to build a more deliberate raster bar with multiple colour bands.

That is the next step toward proper C64 raster effects.
