# Lesson 16 - Raster beam basics

## Goal

Make first contact with the C64 raster beam.

Earlier animation used a simple CPU delay loop.

That made movement visible, but it was not connected to the display timing.

This lesson introduces the VIC-II raster counter:

```text
$d012
```

The program waits for specific raster lines and changes the border colour while the frame is being drawn.

This is the beginning of raster timing.

## What you will build

You will build a C64 program that changes the border colour at different vertical positions on the screen.

The result is a border split into horizontal colour regions.

The program does not print text.

It does not clear the screen.

It does not use tables or zero-page pointers.

It directly touches the VIC-II:

```text
$d012 - current raster line, low 8 bits
$d020 - border colour
$d021 - background colour
```

## What this teaches

This lesson teaches:

- that the C64 display is drawn over time
- that the VIC-II draws the screen line by line
- how to read the raster counter
- how to wait for a raster line
- how changing `$d020` during the frame affects the visible border
- why polling the raster counter is useful but not yet perfect
- why timing matters on old machines
- how the border can become a visual timing tool

The key structure is:

```text
wait for frame -> set border colour -> wait for line -> change border colour
```

This is the first step toward raster bars, split screens, stable timing, raster interrupts, and demo-style effects.

## Important hardware note

This lesson reads the raster counter from:

```asm
$d012
```

`$d012` contains the lower 8 bits of the current raster line.

The C64 display has more than 256 raster lines, so the full raster line also involves bit 7 of `$d011`.

This lesson ignores the high raster bit on purpose.

The chosen raster lines are:

```text
50
120
200
```

These all fit in the lower 8-bit range.

The goal is first contact with raster timing, not full raster-line handling yet.

## Raster beam

The C64 does not draw the whole screen at once.

The VIC-II produces the picture line by line.

The current line being drawn is called the raster line.

By repeatedly reading `$d012`, the CPU can see where the VIC-II currently is in the frame.

This code waits for line 120:

```asm
wait_middle:
    lda $d012
    cmp #120
    bne wait_middle

    rts
```

It means:

```text
read the current raster line
compare it with 120
if it is not 120, keep waiting
return when it is 120
```

When the routine returns, the next instruction runs at roughly that vertical position in the frame.

## Files

This lesson contains:

```text
platforms/c64/lessons/16-raster-beam-basics/
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
// Lesson 16: Raster beam basics
//
// This lesson introduces the VIC-II raster beam.
//
// Earlier animation used a simple CPU delay loop.
// That made movement visible, but it was not connected to the display timing.
//
// The C64 display is drawn line by line by the VIC-II.
// The current raster line can be read from:
//
//   $d012
//
// In this lesson, we wait for specific raster lines and change the border colour.
//
// This is the beginning of raster timing.
// It is not yet stable interrupt-based timing.
// It is direct polling of the raster counter.

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
    lda #$00                  // Load colour 0, black
    sta $d021                 // Store it in the VIC-II background colour register

main_loop:
    jsr wait_next_frame       // Wait until a new frame begins

    lda #$00                  // Load colour 0, black
    sta $d020                 // Set the border colour at the top of the frame

    jsr wait_top              // Wait until the raster reaches the top section

    lda #$06                  // Load colour 6, blue
    sta $d020                 // Change the border colour while the frame is being drawn

    jsr wait_middle           // Wait until the raster reaches the middle section

    lda #$02                  // Load colour 2, red
    sta $d020                 // Change the border colour again

    jsr wait_bottom           // Wait until the raster reaches the lower section

    lda #$05                  // Load colour 5, green
    sta $d020                 // Change the border colour again

    jmp main_loop             // Repeat forever

// -----------------------------------------------------------------------------
// Wait top subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 50.
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

wait_top:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #50                   // Compare it with raster line 50
    bne wait_top              // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait middle subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 120.
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

wait_middle:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #120                  // Compare it with raster line 120
    bne wait_middle           // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait bottom subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter reaches line 200.
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

wait_bottom:
    lda $d012                 // Load current raster line, low 8 bits
    cmp #200                  // Compare it with raster line 200
    bne wait_bottom           // Keep waiting until the line matches

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Wait next frame subroutine
// -----------------------------------------------------------------------------
//
// Waits until the raster counter leaves line 0,
// then waits until it returns to line 0.
//
// This gives the main loop a cleaner frame boundary than only checking
// for $d012 to be zero once.
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
wait_not_zero:
    lda $d012                 // Load current raster line, low 8 bits
    beq wait_not_zero         // If still line 0, wait until the raster leaves line 0

wait_zero:
    lda $d012                 // Load current raster line, low 8 bits
    bne wait_zero             // Wait until the raster returns to line 0

    rts                       // Return to the caller
```

## Code walkthrough

### BASIC loader

The BASIC loader is the same pattern used in earlier lessons.

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

### Start routine

The program first sets the background colour:

```asm
start:
    lda #$00
    sta $d021
```

`$d021` is the VIC-II background colour register.

Colour 0 is black.

The program does not clear screen memory. The BASIC screen remains visible.

That is fine for this lesson because the visible effect is in the border.

### Main loop

The main loop begins by waiting for a new frame:

```asm
main_loop:
    jsr wait_next_frame
```

Then it sets the border colour at the top of the frame:

```asm
lda #$00
sta $d020
```

`$d020` is the VIC-II border colour register.

Then the program waits for raster line 50:

```asm
jsr wait_top
```

and changes the border colour:

```asm
lda #$06
sta $d020
```

The same pattern is repeated for line 120 and line 200.

The loop then starts again:

```asm
jmp main_loop
```

### Waiting for a raster line

This routine waits for raster line 50:

```asm
wait_top:
    lda $d012
    cmp #50
    bne wait_top

    rts
```

`lda $d012` reads the current raster line.

`cmp #50` compares it with line 50.

`bne wait_top` branches back if the current raster line is not 50.

When the raster counter becomes 50, the branch is not taken and the routine returns.

### Changing the border during the frame

The border colour is changed with:

```asm
sta $d020
```

Because the VIC-II is currently drawing the frame, changing `$d020` affects the visible border from that point onward.

That is why the border can have different colours at different vertical positions.

This is the core raster idea:

```text
change a video register while the screen is being drawn
```

### Waiting for the next frame

The frame wait routine is:

```asm
wait_next_frame:
wait_not_zero:
    lda $d012
    beq wait_not_zero

wait_zero:
    lda $d012
    bne wait_zero

    rts
```

It does two things.

First, it waits until the raster leaves line 0:

```asm
beq wait_not_zero
```

Then it waits until the raster returns to line 0:

```asm
bne wait_zero
```

This avoids catching line 0 while the raster is already there.

It gives the main loop a cleaner frame boundary.

This is still not perfect stable timing, but it is a useful first step.

## The key idea

Lesson 16 introduces timing as a hardware concept.

The previous lesson used a delay loop.

A delay loop only burns CPU time.

This lesson reads the display hardware and waits for the VIC-II to reach specific raster lines.

That is a major shift:

```text
delay loop timing -> display timing
```

This is the foundation for classic C64 raster effects.

## Border as a timing tool

The border is not only visual decoration.

It can also be used as a timing tool.

A common technique is:

```asm
lda #$06
sta $d020

jsr expensive_work

lda #$00
sta $d020
```

This turns the border blue before work starts and black when the work finishes.

The height of the blue area shows how much raster time the work consumed.

This is a simple visual profiler.

It is useful because old machines have strict frame budgets.

If an effect takes too long, you can see it.

This idea will become useful in later lessons.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/16-raster-beam-basics
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

You should see horizontal border colour regions.

The BASIC screen text may remain visible. That is expected.

## Machine concepts

This lesson introduces:

- the VIC-II raster beam
- the current raster line
- raster polling
- changing video registers while the frame is being drawn
- border colour changes at different raster positions
- the border as a visual timing aid
- the difference between CPU delay and display timing

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- VIC-II border colour register
- VIC-II background colour register
- infinite loop structure
- subroutines

## Assembly concepts

This lesson introduces or reinforces:

- reading a hardware register
- polling a hardware register
- comparing against immediate values
- waiting with a loop
- direct hardware control
- simple frame-boundary waiting
- `cmp`
- `bne`
- `beq`

It reuses:

- `lda`
- `sta`
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
| `$d012` | VIC-II raster counter, low 8 bits |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |

## Experiments

### Change the raster lines

Change:

```asm
cmp #50
```

Try:

```asm
cmp #30
```

or:

```asm
cmp #80
```

Build and run again.

The colour change should move vertically.

### Change the colours

Change:

```asm
lda #$06
```

to another colour value.

Try values from `$00` to `$0f`.

Build and run again.

### Add another split

Add another wait routine, for example:

```asm
wait_extra:
    lda $d012
    cmp #170
    bne wait_extra

    rts
```

Then call it from the main loop and change the border colour again.

### Remove the frame wait

Remove:

```asm
jsr wait_next_frame
```

Build and run again.

Observe whether the display becomes less stable.

Put it back afterwards.

### Change the background colour

Change:

```asm
sta $d021
```

or the value loaded before it.

The centre of the screen will use the background colour, although the BASIC text may still remain.

### Use the border as a profiler

Add a simple delay routine or some repeated work between two border colour changes.

For example:

```asm
lda #$06
sta $d020

jsr delay

lda #$00
sta $d020
```

The visible height of the coloured area will show how much time the delay used.

## Common mistakes

### Expecting the screen to be cleared

This lesson does not clear screen memory.

The BASIC screen contents may remain visible.

That is expected.

The lesson is about the border and raster timing.

### Thinking `$d012` is the full raster line

`$d012` contains the lower 8 bits of the raster line.

The full raster line also involves bit 7 of `$d011`.

This lesson does not use the high bit yet.

### Expecting perfect stable raster timing

This is polling, not interrupt-based stable timing.

The result should be visible and useful, but it is not yet a cycle-stable raster routine.

### Forgetting that exact waits can be missed

A loop such as:

```asm
lda $d012
cmp #50
bne wait_top
```

waits for an exact value.

If code enters the loop after that line has already passed, it waits for the next time that value appears.

This is one reason more careful timing will matter later.

### Confusing border colour and background colour

`$d020` controls the border.

`$d021` controls the background.

Changing `$d020` is usually more visible for raster experiments because the border surrounds the display area.

## What comes next

Next lesson:

```text
17 - Measuring raster time with the border
```

Now that we can change the border at raster positions, we can use the border as a visual timing tool.

The next lesson will show how much time a piece of code takes by turning the border colour on before the work and off after the work.

That connects directly to old-school performance thinking:

```text
make timing visible
measure the cost of work
understand the frame budget
```

This leads toward raster bars, stable loops, interrupts, and demoscene-style effects.
