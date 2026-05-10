# Lesson 19 - Cleaner raster bars

## Goal

Improve the raster bar from Lesson 18 by replacing rough CPU delay loops with deliberate raster-line waits.

Lesson 18 used this pattern:

```text
set colour
wait a little
set next colour
wait a little
```

This lesson changes the pattern to:

```text
wait for raster line
set colour
wait for next raster line
set next colour
```

The result is a more deliberate raster bar. It is still polling-based timing, not stable interrupt timing.

## What you will build

You will build a C64 program that creates a raster bar in the border by changing `$d020` at chosen raster lines.

The bar uses this colour shape:

```text
blue
light blue
white
light blue
blue
```

Each colour starts at a specific raster line:

```text
100
104
108
112
116
120
```

The program waits for each line, writes the next border colour, and repeats every frame.

## What this teaches

This lesson teaches:

- replacing rough delay timing with raster-line waits
- using `$d012` to choose where colour changes happen
- controlling raster bar thickness through line spacing
- why polling is cleaner than a simple delay loop
- why polling is still not cycle-stable
- why the left and right borders may behave differently
- why stable raster timing matters

The key structure is:

```text
wait line -> write colour -> wait line -> write colour
```

## Important timing note

This lesson is more deliberate than Lesson 18, but it is not yet perfect.

The program waits until `$d012` equals a chosen raster line.

However, when `$d012` reaches that value, the VIC-II has already started drawing that line.

The CPU then still needs time to exit the wait loop, load the colour, and store it to `$d020`.

That means the colour change can happen part-way through the line.

This is why the right border may look stable while the left border may flicker or show partial-line changes.

That is not a failure. It is the lesson.

Polling `$d012` is better than a blind delay loop, but it is not cycle-stable raster timing.

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
platforms/c64/lessons/19-cleaner-raster-bars/
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
// Lesson 19: Cleaner raster bars
//
// This lesson improves the raster bar from Lesson 18.
//
// Lesson 18 used a short delay loop between colour changes.
//
// This lesson removes that rough delay.
// Instead, each colour change waits for a specific raster line.
//
// The program:
//
//   waits for the start of a frame
//   waits for raster line 100
//   changes the border colour
//   waits for raster line 104
//   changes the border colour
//   waits for raster line 108
//   changes the border colour
//   and so on
//
// This is still polling-based timing.
// It is not yet interrupt-driven or cycle-stable.
// But the colour changes are now tied to chosen raster lines,
// not to a rough CPU delay loop.

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

    jsr draw_raster_bar       // Draw one raster bar using raster-line waits

    jmp main_loop             // Repeat forever

// -----------------------------------------------------------------------------
// Wait next frame subroutine
// -----------------------------------------------------------------------------

wait_next_frame:
wait_high_raster:
    lda $d011                 // Read VIC-II control register 1
    bpl wait_high_raster      // Wait until bit 7 is set, meaning raster line >= 256

wait_new_frame:
    lda $d011                 // Read VIC-II control register 1 again
    bmi wait_new_frame        // Wait until bit 7 clears, meaning a new frame has begun

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Draw raster bar subroutine
// -----------------------------------------------------------------------------

draw_raster_bar:
wait_line_100:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #100                  // Wait for raster line 100
    bne wait_line_100         // Keep waiting until line 100 is reached

    lda #$06                  // Blue
    sta $d020                 // Set border colour

wait_line_104:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #104                  // Wait for raster line 104
    bne wait_line_104         // Keep waiting until line 104 is reached

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

wait_line_108:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #108                  // Wait for raster line 108
    bne wait_line_108         // Keep waiting until line 108 is reached

    lda #$01                  // White
    sta $d020                 // Set border colour

wait_line_112:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #112                  // Wait for raster line 112
    bne wait_line_112         // Keep waiting until line 112 is reached

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour

wait_line_116:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #116                  // Wait for raster line 116
    bne wait_line_116         // Keep waiting until line 116 is reached

    lda #$06                  // Blue
    sta $d020                 // Set border colour

wait_line_120:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #120                  // Wait for raster line 120
    bne wait_line_120         // Keep waiting until line 120 is reached

    lda #$00                  // Black
    sta $d020                 // Return border to black

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

The program waits for a new frame, sets the border to black, draws the raster bar, and repeats forever:

```asm
main_loop:
    jsr wait_next_frame
    lda #$00
    sta $d020
    jsr draw_raster_bar
    jmp main_loop
```

### Waiting for the next frame

`$d011` bit 7 is the high raster bit.

The frame wait routine first waits until the raster enters the high raster range, then waits until it wraps back to the top of the frame.

This avoids confusing raster line 0 with raster line 256.

### Waiting for raster lines

The bar starts at raster line 100:

```asm
wait_line_100:
    lda $d012
    cmp #100
    bne wait_line_100

    lda #$06
    sta $d020
```

`$d012` contains the low 8 bits of the current raster line.

The next colour starts at line 104:

```asm
wait_line_104:
    lda $d012
    cmp #104
    bne wait_line_104

    lda #$0e
    sta $d020
```

The gap between line 100 and line 104 means the first colour band is about four raster lines tall.

### Why the left border can flicker

The raster beam draws each line from left to right.

When `$d012` becomes 100, line 100 has already begun.

The CPU still needs time to leave the wait loop, load the colour, and store it to `$d020`.

So the colour change may happen after the left border has already been drawn.

The right border is drawn later, so it is more likely to show the new colour cleanly.

This is not a bug in the lesson. It is evidence that polling `$d012` is not cycle-stable timing.

## The key idea

Lesson 19 replaces rough time with chosen raster lines.

Lesson 18 asked:

```text
How long does this delay loop take?
```

Lesson 19 asks:

```text
Which raster line do we want to change colour on?
```

That is a better mental model for raster effects.

But polling still has limits.

We can choose the line, but not yet the exact cycle inside the line.

## Why this is not the final technique

This lesson still uses polling.

Polling `$d012` is useful and educational, but it does not guarantee that the colour write happens at the same horizontal position every frame.

A proper stable raster routine needs more careful timing.

That comes next.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/19-cleaner-raster-bars
```

Run:

```bash
./build.sh
```

When the C64 screen appears, type:

```basic
RUN
```

You should see a raster bar in the border.

The right border should look more stable than the left border.

## Machine concepts

This lesson introduces:

- raster bars using chosen raster lines
- replacing delay loops with raster-line waits
- partial-line effects caused by left-to-right drawing
- the limitation of polling-based raster timing
- the need for stable timing later

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

- repeated raster waits
- repeated hardware register writes
- branch-based polling loops
- using line spacing as data in code
- explicit unrolled effect code

It reuses:

- `lda`
- `sta`
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

Change all raster line numbers by the same amount.

For example:

```text
100, 104, 108, 112, 116, 120
```

can become:

```text
140, 144, 148, 152, 156, 160
```

The whole bar should move down.

### Make the bar thinner

Use smaller gaps:

```text
100, 102, 104, 106, 108, 110
```

Each colour band should be thinner.

### Make the bar thicker

Use larger gaps:

```text
100, 108, 116, 124, 132, 140
```

Each colour band should be thicker.

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

### Compare with Lesson 18

Go back to Lesson 18 and run the delay-based version.

Then run Lesson 19 again.

Notice the difference between `wait a little` and `wait for this raster line`.

## Common mistakes

### Expecting perfect stability

This is still polling-based timing.

It is more deliberate than a delay loop, but not cycle-stable.

### Thinking line waits control the exact horizontal position

Waiting for `$d012` controls the raster line.

It does not control the exact cycle within that line.

### Trying to fix left-border flicker by guessing earlier lines

Changing the colour one line earlier may or may not improve the result.

Without stable timing, it can also make other parts worse.

The correct long-term fix is more controlled timing.

### Forgetting that the beam draws left to right

The right border is drawn later than the left border.

A colour write that happens part-way through a line can affect the right border but not the left border.

### Expecting full-screen bars

This lesson changes only `$d020`.

That controls the border.

Full-width bars across the screen area require changing `$d021` too, and usually using a mostly blank screen.

That comes later.

## What comes next

Next lesson:

```text
20 - Stable raster timing
```

Lesson 19 gave us cleaner raster bars, but it also exposed the next problem:

```text
waiting for a raster line is not the same as changing colour at a stable horizontal position
```

Lesson 20 should take the next step toward doing this properly.

We will keep the code explicit, but start learning what stable raster timing requires.
