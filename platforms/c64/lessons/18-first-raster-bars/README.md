# Lesson 18 - First raster bars

## Goal

Create the first simple raster bar on the Commodore 64.

Lessons 16 and 17 introduced raster polling, border colour changes, and the border as a timing tool.

This lesson uses the same ideas to create a visible effect.

The program waits for a raster line, changes the border colour several times, and uses a short delay between colour changes.

The result is a simple horizontal raster bar in the border.

## What you will build

You will build a C64 program that creates a simple colour bar in the border.

The bar uses this colour shape:

```text
blue
light blue
white
light blue
blue
```

The bar appears around a chosen raster line.

The program does not use sprites.

It does not use interrupts.

It does not use tables.

It does not yet change the full screen background.

It only changes the border colour register:

```text
$d020
```

## What this teaches

This lesson teaches:

- how changing `$d020` during the frame creates visible horizontal colour bands
- that the VIC-II keeps drawing while the CPU runs code
- why elapsed CPU time becomes visible on the screen
- how rough delay loops can create raster bands
- why rough delay loops are not the final technique
- why cleaner raster-line waits come next

The key structure is:

```text
wait for raster line -> set colour -> wait briefly -> set next colour
```

This is the first recognisable raster-bar effect in the project.

## Important timing note

This lesson uses a deliberately simple delay routine:

```asm
short_delay:
    ldx #$10

delay_loop:
    dex
    bne delay_loop

    rts
```

This is not elite raster timing.

It is a teaching step.

The delay keeps each colour active for long enough that the VIC-II draws several lines with that colour.

That proves the important idea:

```text
colour writes plus elapsed CPU time create visible raster bands
```

Later lessons will replace this rough delay with more deliberate raster-line timing.

## Important interrupt note

This lesson uses:

```asm
sei
```

`sei` disables normal maskable IRQ interrupts.

The normal C64 system interrupt can disturb timing slightly.

For this controlled raster lesson, disabling normal IRQs gives a cleaner result.

This program loops forever and is not trying to return politely to BASIC.

Proper interrupt setup and cleanup will be covered later.

## Files

This lesson contains:

```text
platforms/c64/lessons/18-first-raster-bars/
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
// Lesson 18: First raster bars
//
// This lesson creates the first simple raster bar.
//
// Lessons 16 and 17 introduced raster polling and the border as a timing tool.
//
// This lesson uses the same idea to create a visible effect.
//
// The program:
//
//   waits for the start of a frame
//   waits for a chosen raster line
//   changes the border colour several times
//   returns the border to black
//   repeats forever
//
// This is still polling-based timing.
// It is not yet interrupt-driven or cycle-stable.
// But it is the first step toward classic raster effects.

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
    sei                       // Disable normal IRQ interrupts for cleaner timing

    lda #$00                  // Load colour 0, black
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

main_loop:
    jsr wait_next_frame       // Wait until a new frame begins

    lda #$00                  // Start each frame with a black border
    sta $d020                 // Store black in the border colour register

    jsr wait_bar_line         // Wait until the raster reaches the bar position

    jsr draw_raster_bar       // Draw one simple raster bar

    jmp main_loop             // Repeat forever

// -----------------------------------------------------------------------------
// Wait next frame subroutine
// -----------------------------------------------------------------------------
//
// Waits for the raster to enter the high raster range,
// then waits until it wraps back to the start of the next frame.
//
// $d012 contains the low 8 bits of the raster line.
// Bit 7 of $d011 contains the high raster bit.
//
// This avoids mistaking raster line 256 for raster line 0.
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
//   A
//   flags
//
// Preserves:
//
//   X
//   Y

wait_next_frame:
wait_high_raster:
    lda $d011                 // Read VIC-II control register 1
    bpl wait_high_raster      // Wait until bit 7 is set, meaning raster line >= 256

wait_new_frame:
    lda $d011                 // Read VIC-II control register 1 again
    bmi wait_new_frame        // Wait until bit 7 clears, meaning a new frame has begun

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait bar line subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 100.
//
// This is where the raster bar begins.
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
//   A
//   flags
//
// Preserves:
//
//   X
//   Y

wait_bar_line:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #100                  // Compare it with raster line 100
    bne wait_bar_line         // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Draw raster bar subroutine
// -----------------------------------------------------------------------------
//
// Draws a simple raster bar by changing the border colour several times.
//
// Each colour is held briefly by a small delay.
// This creates visible horizontal bands.
//
// Input:
//
//   none
//
// Output:
//
//   border colour changed during the frame
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

draw_raster_bar:
    lda #$06                  // Blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$01                  // White
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$06                  // Blue
    sta $d020                 // Set border colour
    jsr short_delay           // Hold the colour briefly

    lda #$00                  // Black
    sta $d020                 // Return border to black

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Short delay subroutine
// -----------------------------------------------------------------------------
//
// Holds each colour for a short time.
//
// This is deliberately simple.
// It burns CPU time so each colour remains visible for more than a few cycles.
//
// Later lessons will replace this rough delay with cleaner raster-line timing.
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

short_delay:
    ldx #$10                  // Delay counter

delay_loop:
    dex                       // Count down
    bne delay_loop            // Repeat until X reaches zero

    rts                       // Return to the caller
```

## Code walkthrough

### BASIC loader

The BASIC loader creates:

```basic
10 SYS 2061
```

When you type `RUN`, BASIC starts the machine code at `$080d`.

### Disabling normal IRQ interrupts

The program begins with:

```asm
sei
```

This disables normal IRQ interrupts.

For this controlled raster lesson, that reduces timing disturbance from the normal KERNAL interrupt.

### Initial colours

The program sets border and background to black:

```asm
lda #$00
sta $d020
sta $d021
```

`$d020` controls the border colour.

`$d021` controls the background colour.

### Main loop

The main loop begins with a frame wait:

```asm
jsr wait_next_frame
```

Then it starts the frame with a black border:

```asm
lda #$00
sta $d020
```

Then it waits for the raster line where the bar should begin:

```asm
jsr wait_bar_line
```

Then it draws the raster bar:

```asm
jsr draw_raster_bar
```

Finally, it repeats forever:

```asm
jmp main_loop
```

### Waiting for the next frame

The frame wait routine is:

```asm
wait_next_frame:
wait_high_raster:
    lda $d011
    bpl wait_high_raster

wait_new_frame:
    lda $d011
    bmi wait_new_frame

    rts
```

`$d011` bit 7 is the high raster bit.

This routine waits until the raster enters the high raster range, then waits until it wraps back to the top of the frame.

This avoids confusing raster line 0 with raster line 256.

### Waiting for the bar line

The bar starts around raster line 100:

```asm
wait_bar_line:
    lda $d012
    cmp #100
    bne wait_bar_line

    rts
```

`$d012` contains the low 8 bits of the current raster line.

The loop waits until the current line equals 100.

### Drawing the bar

The bar is created by repeatedly changing `$d020`:

```asm
lda #$06
sta $d020
jsr short_delay

lda #$0e
sta $d020
jsr short_delay
```

The CPU changes the border colour.

The VIC-II keeps drawing the screen.

While `short_delay` runs, the chosen border colour remains active.

That creates a visible horizontal colour band.

### Short delay

The delay routine is:

```asm
short_delay:
    ldx #$10

delay_loop:
    dex
    bne delay_loop

    rts
```

This burns CPU time.

It gives the VIC-II time to draw several raster lines before the next colour change.

This is rough timing, but it is useful for first contact.

## The key idea

The CPU is not drawing the raster bar line by line.

The VIC-II is drawing the display continuously.

The CPU is changing a colour register while that drawing happens.

That is why this works:

```text
change colour
let time pass
change colour again
```

The raster bar is a visible result of changing hardware state while the frame is being drawn.

## Why this is not the final technique

This lesson uses `short_delay`.

That is intentionally simple, but not precise.

A better raster bar should wait for specific raster lines between colour changes, or eventually use interrupts and cycle-aware timing.

So the purpose of this lesson is not to create perfect bars.

The purpose is to understand why colour changes during the frame create raster bands.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/18-first-raster-bars
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

You should see a simple raster bar in the border.

## Machine concepts

This lesson introduces:

- first raster bar
- visible colour bands from timed colour changes
- border-only raster effects
- rough CPU-loop timing
- the VIC-II continuing to draw while the CPU runs

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- `sei`
- VIC-II control register `$d011`
- VIC-II raster counter `$d012`
- VIC-II border colour register `$d020`
- VIC-II background colour register `$d021`
- raster polling
- frame waiting

## Assembly concepts

This lesson introduces or reinforces:

- repeated hardware register writes
- short delay loops
- holding a hardware state for visible time
- subroutine structure for small hardware routines

It reuses:

- `lda`
- `sta`
- `ldx`
- `dex`
- `bne`
- `bpl`
- `bmi`
- `cmp`
- `jsr`
- `rts`
- `jmp`
- `.word`
- `.byte`
- `.text`

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$d011` | VIC-II control register 1, includes high raster bit |
| `$d012` | VIC-II raster counter low byte |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Move the bar

Change:

```asm
cmp #100
```

Try:

```asm
cmp #60
```

or:

```asm
cmp #150
```

Build and run again.

The raster bar should move up or down.

### Change the band thickness

Change:

```asm
ldx #$10
```

Try:

```asm
ldx #$08
```

or:

```asm
ldx #$20
```

A smaller value should make each colour band thinner.

A larger value should make each colour band thicker.

### Change the colours

Change the colour values in `draw_raster_bar`.

For example:

```asm
lda #$02
```

uses red.

```asm
lda #$07
```

uses yellow.

Try creating your own colour pattern.

### Add another colour step

Add another colour write and delay inside `draw_raster_bar`.

For example:

```asm
lda #$03
sta $d020
jsr short_delay
```

Build and run again.

### Remove `sei`

Temporarily remove:

```asm
sei
```

Build and run again.

Observe whether timing becomes less stable.

Put it back afterwards.

## Common mistakes

### Expecting full-screen bars

This lesson changes only `$d020`.

That controls the border.

Full-width bars across the screen area require changing `$d021` too, and usually using a mostly blank screen.

That comes later.

### Thinking the delay is exact raster timing

`short_delay` does not wait for a raster line.

It only burns CPU time.

The next lesson will replace this with more deliberate raster-line waits.

### Making the delay too large

If the delay is too long, the bar becomes very thick or may run into unintended parts of the frame.

Start with small values.

### Forgetting that the VIC-II is doing the drawing

The CPU only changes colour registers.

The VIC-II draws the visible result.

### Expecting cycle-stable output

This is polling-based and delay-based.

It is useful and visible, but not yet cycle-stable.

## What comes next

Next lesson:

```text
19 - Cleaner raster bars
```

Now that we have seen a raster bar created by colour writes and elapsed CPU time, the next step is to replace the rough delay loop.

Instead of saying:

```text
wait a little
```

we will say:

```text
wait until this raster line
```

That gives us more deliberate raster bars and prepares us for full-screen bars, moving bars, sine movement, and eventually interrupt-driven timing.
