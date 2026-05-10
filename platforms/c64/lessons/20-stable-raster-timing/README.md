# Lesson 20 - Stable raster timing

## Goal

Make the raster bar from Lesson 19 more stable by reducing repeated raster-line polling.

Lesson 19 waited for every colour change by reading `$d012`.

That was more deliberate than a rough delay loop, but it still produced unstable horizontal timing.

This lesson changes the approach:

```text
synchronise once
then use fixed CPU timing between colour changes
```

The result is not perfect, but it should be more stable.

## What you will build

You will build a C64 program that creates a raster bar in the border.

The bar still uses this colour shape:

```text
blue
light blue
white
light blue
blue
```

But instead of waiting for each colour boundary with `$d012`, the program:

```text
waits for a setup raster line
waits until the raster leaves that line
uses a small fixed delay
draws the bar using repeated fixed timing
```

This is a step toward stable raster effects.

## What this teaches

This lesson teaches:

- the difference between vertical timing and horizontal timing
- why polling `$d012` controls the line but not the exact cycle
- why repeated polling can cause visible jitter
- why fixed instruction timing can be more stable once synchronised
- why cycle timing matters for raster effects
- why this is still not the final technique

The key structure is:

```text
raster sync -> fixed delay -> colour writes with fixed timing
```

## Important timing note

This lesson is more stable than Lesson 19, but it is still not perfect.

The routine uses fixed CPU timing after one raster synchronisation point.

That means the colour changes are more predictable than repeated `$d012` polling.

However, the delay routine is still approximate.

This is not yet cycle-exact code.

The purpose of this lesson is to show the next concept:

```text
Polling gets us near the right place.
Fixed timing makes what happens next more predictable.
```

## Important interrupt note

This lesson uses:

```asm
sei
```

`sei` disables normal maskable IRQ interrupts.

The normal C64 system interrupt can disturb timing.

For this controlled raster lesson, disabling normal IRQs gives a cleaner result.

This program loops forever and is not trying to return politely to BASIC.

Proper interrupt setup and cleanup will be covered later.

## Files

This lesson contains:

```text
platforms/c64/lessons/20-stable-raster-timing/
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
// Lesson 20: Stable raster timing
//
// This lesson improves the raster bar from Lesson 19.
//
// Lesson 19 waited for specific raster lines and changed the border colour.
// That was cleaner than a rough delay loop, but the left border could still
// flicker because the colour write happened at slightly different horizontal
// positions inside the raster line.
//
// This lesson introduces a more controlled timing pattern:
//
//   wait for a raster line
//   wait until the raster has moved to the next line
//   run a small fixed delay
//   write colours with predictable timing
//
// This is still not full interrupt-driven stable raster timing.
// But it is the next step toward understanding why cycle timing matters.

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

    jsr wait_bar_start        // Wait for the raster to reach our setup line

    jsr stabilise_after_line  // Move to a more predictable point after the line changes

    jsr draw_stable_bar       // Draw a bar using fixed instruction timing

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
// Wait bar start subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 99.
//
// The bar itself will begin shortly after this.
// We use this line as a setup line before drawing.
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

wait_bar_start:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #99                   // Wait for setup raster line 99
    bne wait_bar_start        // Keep waiting until line 99 is reached

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Stabilise after line subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster leaves the setup line,
// then burns a small fixed number of cycles.
//
// The first wait synchronises us to a line change.
// The NOPs then move the colour writes a little further into the next line.
//
// This is not a perfect stabiliser.
// It is a simple first step toward cycle-aware timing.
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

stabilise_after_line:
wait_leave_line:
    lda $d012                 // Load current raster line
    cmp #99                   // Are we still on setup line 99?
    beq wait_leave_line       // If yes, wait until the raster leaves it

    nop                       // Fixed 2-cycle delay
    nop                       // Fixed 2-cycle delay
    nop                       // Fixed 2-cycle delay
    nop                       // Fixed 2-cycle delay

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Draw stable bar subroutine
// -----------------------------------------------------------------------------
//
// Draws a raster bar using fixed instruction timing instead of waiting
// for each raster line.
//
// This means the colour changes are spaced by known instruction sequences.
//
// The bar is still not perfect, but it should be more horizontally stable
// than the line-polling version from Lesson 19.
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

draw_stable_bar:
    lda #$06                  // Blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$01                  // White
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$06                  // Blue
    sta $d020                 // Set border colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$00                  // Black
    sta $d020                 // Return border to black

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait four lines subroutine
// -----------------------------------------------------------------------------
//
// Burns roughly the amount of CPU time taken by a few raster lines.
//
// A PAL C64 raster line is 63 cycles.
// Four raster lines are roughly 252 cycles.
//
// This simple routine is not cycle-perfect.
// It is deliberately close enough to show how fixed code time can replace
// repeated polling for each colour band.
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

wait_four_lines:
    ldx #$28                  // Delay counter chosen to approximate a few raster lines

wait_four_lines_loop:
    dex                       // Count down
    bne wait_four_lines_loop  // Repeat until X reaches zero

    rts                       // Return to the caller
```

## Code walkthrough

### BASIC loader

The BASIC loader creates:

```basic
10 SYS 2061
```

When you type `RUN`, BASIC starts the machine code at `$080d`.

### Main loop

The main loop waits for the next frame, resets the border to black, synchronises near the raster bar position, and draws the bar:

```asm
main_loop:
    jsr wait_next_frame
    lda #$00
    sta $d020
    jsr wait_bar_start
    jsr stabilise_after_line
    jsr draw_stable_bar
    jmp main_loop
```

### Waiting for the next frame

The frame wait routine uses bit 7 of `$d011`.

This avoids confusing raster line 0 with raster line 256.

It gives the program a clean frame boundary before drawing the bar.

### Waiting for the setup line

The program waits for raster line 99:

```asm
wait_bar_start:
    lda $d012
    cmp #99
    bne wait_bar_start
    rts
```

This is not the visible bar line itself.

It is a setup line.

### Stabilising after the line

After line 99 is detected, the program waits until `$d012` changes:

```asm
wait_leave_line:
    lda $d012
    cmp #99
    beq wait_leave_line
```

This means the raster has moved beyond the setup line.

Then the program runs a few fixed `nop` instructions:

```asm
nop
nop
nop
nop
```

Each `nop` takes 2 cycles.

This moves the next colour write to a more predictable position after the line transition.

### Drawing with fixed timing

Unlike Lesson 19, the bar does not wait for every colour line.

It writes the first colour:

```asm
lda #$06
sta $d020
```

Then it waits using fixed code time:

```asm
jsr wait_four_lines
```

Then it writes the next colour:

```asm
lda #$0e
sta $d020
```

The same instruction sequence runs each frame.

That makes the timing more stable.

## The key idea

Lesson 20 changes the timing model.

Lesson 19 used repeated polling:

```text
wait for line 100
write colour
wait for line 104
write colour
wait for line 108
write colour
```

Lesson 20 uses one synchronisation point and then fixed timing:

```text
sync once
write colour
wait fixed amount
write colour
wait fixed amount
```

This is more stable because the CPU follows the same instruction path every frame after the synchronisation point.

## Why this is still not the final technique

This lesson is more stable, but not elegant and not cycle-perfect.

The delay routine is still approximate.

The lesson exists to teach the principle:

```text
stable raster effects need control over both the raster line and the cycle inside the line
```

The fully proper path still leads toward raster interrupts and cycle-aware code.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/20-stable-raster-timing
```

Run:

```bash
./build.sh
```

When the C64 screen appears, type:

```basic
RUN
```

You should see a raster bar that is more stable than Lesson 19.

## Machine concepts

This lesson introduces:

- horizontal timing inside a raster line
- the idea of synchronising once, then relying on fixed timing
- why raster-line polling alone is not enough
- why cycle awareness matters

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

- `nop`
- fixed-cycle delay
- repeated fixed instruction sequences
- timing as part of program behaviour
- approximate cycle budgeting

It reuses:

- `lda`
- `sta`
- `ldx`
- `dex`
- `bne`
- `beq`
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

### Change the start line

Change:

```asm
cmp #99
```

to another value.

Try:

```asm
cmp #130
```

The raster bar should move down.

### Change the stabilising NOPs

Remove one `nop` or add more.

Observe whether the bar shifts horizontally or becomes less stable.

### Change the band thickness

Change:

```asm
ldx #$28
```

inside `wait_four_lines`.

A smaller value should make the colour bands thinner.

A larger value should make them thicker.

### Compare with Lesson 19

Run Lesson 19 again.

Then run Lesson 20.

Notice the difference between repeated polling and one sync plus fixed timing.

## Common mistakes

### Thinking this is perfect raster timing

This is more stable than Lesson 19, but still not perfect.

The code is still polling-based.

### Confusing line stability and cycle stability

`$d012` tells us the raster line.

It does not by itself tell us the exact cycle inside that line.

### Expecting elegance

This lesson is deliberately a bridge.

It is not the final elegant method.

It exists so that the need for better timing becomes obvious.

### Forgetting why `sei` is used

Normal IRQs can disturb timing.

`sei` disables them for this controlled lesson.

## What comes next

Next lesson:

```text
21 - Full-screen raster bars
```

Now that the timing is more stable, we can make the effect more visually satisfying.

Instead of changing only the border colour, we will also change the background colour:

```asm
sta $d020
sta $d021
```

That will make the raster bars span the full width of the visible screen area, not just the border.

This is the next step toward more recognisable C64 demo effects.
