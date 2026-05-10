# Lesson 21 - Full-screen raster bars

## Goal

Extend the raster bar from the border into the visible screen area.

Earlier raster-bar lessons changed only the border colour:

```asm
sta $d020
```

This lesson changes both the border and the background colour:

```asm
sta $d020
sta $d021
```

That makes the raster bar span the full visible width of the display, as long as the screen is filled with spaces.

## What you will build

You will build a C64 program that creates a full-screen raster bar.

The bar changes:

```text
$d020 - border colour
$d021 - background colour
```

The screen is cleared to spaces first so that background colour changes are visible across the main screen area.

The bar uses this colour shape:

```text
blue
light blue
white
light blue
blue
```

## What this teaches

This lesson teaches:

- the difference between border colour and background colour
- why changing `$d021` makes the main screen area change colour
- why the screen should contain spaces for background colour changes to be clearly visible
- why full-screen raster bars are harder than border-only raster bars
- why writing two VIC-II registers creates visible timing differences
- why cycle timing matters even more once multiple registers are involved

The key structure is:

```text
set border colour
set background colour
wait fixed time
set next colours
```

## Important timing note

This lesson makes the raster bar span the full screen, but it also exposes a new timing problem.

The code writes two registers:

```asm
sta $d020
sta $d021
```

or, if you choose to test the opposite order:

```asm
sta $d021
sta $d020
```

These two writes do not happen at the same cycle.

The VIC-II is still drawing the screen while the CPU executes those instructions.

That means the border colour and the background colour change at slightly different horizontal positions.

The result can look skewed.

This is expected.

It is the main learning point of the lesson.

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
platforms/c64/lessons/21-full-screen-raster-bars/
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
// Lesson 21: Full-screen raster bars
//
// This lesson extends the raster bar from Lesson 20.
//
// Earlier raster bars changed only the border colour:
//
//   $d020
//
// This lesson changes both:
//
//   $d020 - border colour
//   $d021 - background colour
//
// This makes the raster bar span the full visible screen area,
// as long as the screen contains spaces.
//
// The timing is still polling-based.
// We are still not using raster interrupts yet.

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

    lda #$00                  // Load colour 0, black
    sta clear_colour          // Store colour used by clear_screen

    jsr clear_screen          // Clear screen memory and colour RAM

main_loop:
    jsr wait_next_frame       // Wait until a new frame begins

    lda #$00                  // Start each frame with black
    sta $d020                 // Set border colour to black
    sta $d021                 // Set background colour to black

    jsr wait_bar_start        // Wait for the raster to reach our setup line

    jsr stabilise_after_line  // Move to a more predictable point after the line changes

    jsr draw_full_bar         // Draw a full-screen raster bar

    jmp main_loop             // Repeat forever

// -----------------------------------------------------------------------------
// Clear screen subroutine
// -----------------------------------------------------------------------------
//
// Clears screen memory to spaces and initialises colour RAM.
//
// Input:
//
//   clear_colour - colour value used for colour RAM
//
// Output:
//
//   screen memory filled with spaces
//   colour RAM initialised
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

    lda clear_colour          // Load colour used for cleared cells
    sta $d800,x               // Initialise colour RAM page $d8
    sta $d900,x               // Initialise colour RAM page $d9
    sta $da00,x               // Initialise colour RAM page $da
    sta $db00,x               // Initialise colour RAM page $db

    inx                       // Move to the next position
    bne clear                 // Repeat until X wraps from $ff to $00

    rts                       // Return to the caller

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
// This is not perfect cycle-stable timing.
// It is a simple bridge between polling and proper raster timing.
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
// Draw full bar subroutine
// -----------------------------------------------------------------------------
//
// Draws a raster bar by changing both border and background colour.
//
// $d020 controls the border.
// $d021 controls the background.
//
// Because the screen is filled with spaces, changes to $d021 are visible
// across the main screen area.
//
// Input:
//
//   none
//
// Output:
//
//   border and background colour changed during the frame
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

draw_full_bar:
    lda #$06                  // Blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$01                  // White
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$0e                  // Light blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$06                  // Blue
    sta $d020                 // Set border colour
    sta $d021                 // Set background colour

    jsr wait_four_lines       // Hold colour for roughly four raster lines

    lda #$00                  // Black
    sta $d020                 // Return border to black
    sta $d021                 // Return background to black

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
// It keeps the timing model consistent with Lesson 20.
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

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

clear_colour:
    .byte 0                   // Colour used when initialising colour RAM
```

## Code walkthrough

### BASIC loader

The BASIC loader creates:

```basic
10 SYS 2061
```

When you type `RUN`, BASIC starts the machine code at `$080d`.

### Clearing the screen

This lesson clears the screen again.

That is because `$d021` controls the background colour, and background colour changes are most visible when the screen contains spaces.

The clear routine writes screen code `$20`, which is a space:

```asm
lda #$20
sta $0400,x
sta $0500,x
sta $0600,x
sta $0700,x
```

It also initialises colour RAM:

```asm
lda clear_colour
sta $d800,x
sta $d900,x
sta $da00,x
sta $db00,x
```

### Main loop

The main loop waits for the next frame, resets the colours to black, waits for the bar start, stabilises slightly, and draws the full bar:

```asm
main_loop:
    jsr wait_next_frame

    lda #$00
    sta $d020
    sta $d021

    jsr wait_bar_start
    jsr stabilise_after_line
    jsr draw_full_bar

    jmp main_loop
```

### Drawing the full bar

The key difference from earlier raster bars is this:

```asm
lda #$06
sta $d020
sta $d021
```

The same colour is written to both border and background.

This makes the bar appear across:

```text
left border
main screen area
right border
```

### Why the bar can look skewed

The two writes do not happen at the same time:

```asm
sta $d020
sta $d021
```

The CPU writes `$d020` first.

Then it writes `$d021`.

The VIC-II continues drawing while those instructions execute.

So the border and the background do not change at exactly the same horizontal position.

That is why the full-screen bar can look skewed.

If you reverse the order:

```asm
sta $d021
sta $d020
```

the skew changes.

This shows that full-screen raster bars are more timing-sensitive than border-only bars.

## The key idea

Lesson 21 extends raster bars from the border to the full screen.

That requires changing both:

```text
border colour
background colour
```

But changing two registers takes time.

That visible timing gap is the important lesson.

## Why this is not the final technique

This lesson is visually more satisfying than border-only bars, but it exposes a new precision problem.

The bar is full-screen, but the colour transitions are not perfectly aligned.

That is not the final form.

It prepares us for Lesson 22, where we will focus on alignment.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/21-full-screen-raster-bars
```

Run:

```bash
./build.sh
```

When the C64 screen appears, type:

```basic
RUN
```

You should see a raster bar that spans the border and the main screen area.

## Machine concepts

This lesson introduces:

- full-screen raster bars
- background colour changes during the frame
- the relationship between screen spaces and `$d021`
- the visible timing gap between two hardware register writes
- skew caused by sequential register writes

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- `sei`
- VIC-II control register `$d011`
- VIC-II raster counter `$d012`
- VIC-II border colour register `$d020`
- VIC-II background colour register `$d021`
- screen memory
- colour RAM
- clear screen routine
- raster polling
- fixed timing after synchronisation

## Assembly concepts

This lesson introduces or reinforces:

- writing the same value to multiple hardware registers
- how instruction order affects visible output
- why sequential writes are not simultaneous
- using existing routines for a new visual purpose

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
- `nop`
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
| `$0400-$07ff` | Screen memory cleared to spaces |
| `$d800-$dbff` | Colour RAM initialised |
| `$d011` | VIC-II control register 1, includes high raster bit |
| `$d012` | VIC-II raster counter low byte |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Reverse the register order

Change:

```asm
sta $d020
sta $d021
```

to:

```asm
sta $d021
sta $d020
```

Do this for each colour step.

Build and run again.

The skew should change.

### Change the bar position

Change:

```asm
cmp #99
```

to another value.

Try:

```asm
cmp #130
```

The full-screen raster bar should move down.

### Change the colours

Change the colour values in `draw_full_bar`.

For example:

```asm
lda #$02
```

uses red.

```asm
lda #$07
```

uses yellow.

### Use different border and background colours

Instead of:

```asm
lda #$06
sta $d020
sta $d021
```

try:

```asm
lda #$06
sta $d020

lda #$0e
sta $d021
```

This shows that the border and background are controlled by separate registers.

### Do not clear the screen

Comment out:

```asm
jsr clear_screen
```

Build and run again.

The main screen area will no longer look as clean because existing screen characters remain visible.

Put the clear routine back afterwards.

## Common mistakes

### Expecting the bar to align perfectly

This lesson writes two registers one after the other.

They cannot change on the same CPU cycle.

Some skew is expected.

### Forgetting that `$d021` is background colour

`$d021` does not change character colour RAM.

It changes the background colour behind characters.

That is why clearing the screen to spaces makes the effect clearer.

### Expecting full-screen bars without clearing the screen

If the screen contains visible characters, the background colour change may be less clean.

### Thinking this is already the proper final method

This is a necessary step, but not the final method.

The next lesson focuses on alignment.

## What comes next

Next lesson:

```text
22 - Aligning full-screen raster bars
```

Lesson 21 showed that full-screen bars work, but also that writing `$d020` and `$d021` sequentially creates visible skew.

Lesson 22 will focus on that problem directly.

We will investigate how instruction order and timing affect the alignment between the border and the main screen area.
