# Lesson 17 - Measuring raster time with the border

## Goal

Use the C64 border as a simple visual profiler.

Lesson 16 introduced the raster beam and showed that changing `$d020` during the frame changes the border colour at different vertical positions.

This lesson turns the border blue before a piece of work starts, then turns it black after the work is finished.

The height of the blue border area shows roughly how much raster time the work consumed.

## What you will build

You will build a C64 program where holding SPACE shows how much time a small workload takes.

When SPACE is not held, the border stays black.

When SPACE is held, a blue timing band appears near the top of the frame.

The program:

```text
waits for the next frame
checks whether SPACE is held
turns the border blue if timing display is enabled
runs a small workload
turns the border black
repeats forever
```

## What this teaches

This lesson teaches:

- using the border as a timing ruler
- measuring CPU work visually
- making performance visible
- reading the keyboard through the CIA keyboard matrix
- pressed keys reading as 0
- why normal system IRQs can disturb timing
- using `sei` to disable normal IRQ interrupts
- the difference between useful polling and stable interrupt timing
- why proper raster interrupts come later

The key structure is:

```text
frame boundary -> optional border on -> measured work -> border off
```

## Important interrupt note

This lesson uses:

```asm
sei
```

`sei` means set interrupt disable flag.

It disables normal maskable IRQ interrupts.

The C64 normally uses interrupts for system tasks such as keyboard scanning and cursor handling. Those interrupts can briefly interrupt our code.

When the border is being used as a timing ruler, even a small interruption becomes visible as jitter or flicker.

For this controlled lesson, we disable normal IRQs to make the timing display cleaner.

This program loops forever and is not trying to be a polite BASIC program.

Proper interrupt setup and cleanup will be covered later.

## Important hardware note

This lesson uses these hardware registers:

```text
$d011 - VIC-II control register 1, includes the high raster bit
$d020 - VIC-II border colour
$d021 - VIC-II background colour
$dc00 - CIA #1 port A, keyboard column selection
$dc01 - CIA #1 port B, keyboard row input
```

Lesson 16 used `$d012`, the low 8 bits of the raster counter.

This lesson uses bit 7 of `$d011` to wait for the frame to wrap from the high raster range back to the top of the next frame.

## Border as a timing tool

The border can be used as a visual profiler.

The basic idea is:

```asm
lda #$06
sta $d020

jsr expensive_work

lda #$00
sta $d020
```

That means:

```text
turn border blue
do work
turn border black
```

If the work takes a short time, the blue band is short.

If the work takes a long time, the blue band is taller.

If the work takes too long, it may run far down the frame or even into the next frame.

This is a classic way to make timing visible on old machines.

## Keyboard input

This lesson reads the SPACE key directly from the C64 keyboard matrix.

The C64 keyboard is arranged as a matrix.

CIA #1 port A at `$dc00` selects a keyboard column.

CIA #1 port B at `$dc01` reads the keyboard rows.

For SPACE, the program uses:

```asm
lda #%01111111
sta $dc00

lda $dc01
and #%00010000
```

A pressed key reads as 0.

A released key reads as 1.

So if bit 4 is clear, SPACE is pressed.

## Files

This lesson contains:

```text
platforms/c64/lessons/17-measuring-raster-time/
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
// Lesson 17: Measuring raster time with the border
//
// This lesson uses the C64 border as a simple visual profiler.
//
// Lesson 16 changed the border colour at fixed raster positions.
//
// This lesson turns the border colour on before a piece of work,
// and turns it off after the work is finished.
//
// The height of the coloured border area shows roughly how much raster time
// the work consumed.
//
// The timing display is only shown while SPACE is held down.
//
// This lesson also disables normal IRQ interrupts with sei.
// That makes the timing display cleaner because the normal KERNAL IRQ
// no longer interrupts our measurement loop.
//
// This is a common old-school technique.
// It makes performance visible.

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

    lda #$00                  // Load colour 0, black
    sta $d020                 // Start the frame with a black border

    jsr is_space_pressed      // Check whether SPACE is currently held
    sta show_timing           // Store 1 if SPACE is pressed, otherwise 0

    lda show_timing           // Load timing display flag
    beq skip_border_on        // If zero, do not turn the border blue

    lda #$06                  // Load colour 6, blue
    sta $d020                 // Turn border blue before measured work starts

skip_border_on:
    jsr do_work               // Run the work we want to measure

    lda #$00                  // Load colour 0, black
    sta $d020                 // Turn border black after the measured work ends

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
// Is space pressed subroutine
// -----------------------------------------------------------------------------
//
// Checks whether the SPACE key is currently pressed.
//
// The C64 keyboard is arranged as a matrix.
//
// CIA #1 port A at $dc00 selects a keyboard column.
// CIA #1 port B at $dc01 reads the keyboard rows.
//
// For SPACE:
//
//   write %01111111 to $dc00
//   read $dc01
//   test bit 4
//
// A pressed key reads as 0.
// A released key reads as 1.
//
// Input:
//
//   none
//
// Output:
//
//   A = 1 if SPACE is pressed
//   A = 0 if SPACE is not pressed
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

is_space_pressed:
    lda #%01111111            // Select the keyboard column containing SPACE
    sta $dc00                 // Write column selection to CIA #1 port A

    lda $dc01                 // Read keyboard rows from CIA #1 port B
    and #%00010000            // Isolate bit 4, the SPACE row bit
    beq space_is_pressed      // If bit is 0, SPACE is pressed

space_not_pressed:
    lda #0                    // Return 0, SPACE is not pressed
    rts                       // Return to the caller

space_is_pressed:
    lda #1                    // Return 1, SPACE is pressed
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Do work subroutine
// -----------------------------------------------------------------------------
//
// Burns CPU time so that the border shows a visible timing band.
//
// This routine does not calculate anything useful yet.
// Its purpose is to create work that takes time.
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
//   X
//   Y
//   flags
//
// Preserves:
//
//   none

do_work:
    ldx #$02                  // Outer work counter

work_outer:
    ldy #$ff                  // Inner work counter

work_inner:
    dey                       // Count down inner loop
    bne work_inner            // Repeat until Y reaches zero

    dex                       // Count down outer loop
    bne work_outer            // Repeat until X reaches zero

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// State data
// -----------------------------------------------------------------------------

show_timing:
    .byte 0                   // 1 = show border timing, 0 = hide it
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

The normal C64 system interrupt can briefly interrupt our code.

That is useful for the system, but not useful when the border is being used as a timing ruler.

By disabling normal IRQs, the timing band becomes much more stable.

### Main loop

The main loop begins by waiting for a new frame:

```asm
jsr wait_next_frame
```

Then it sets the border to black:

```asm
lda #$00
sta $d020
```

Then it checks whether SPACE is held:

```asm
jsr is_space_pressed
sta show_timing
```

If SPACE is pressed, the border is turned blue before the measured work:

```asm
lda #$06
sta $d020
```

After `do_work` finishes, the border is turned black:

```asm
lda #$00
sta $d020
```

The visible blue band therefore shows how long `do_work` took.

### Frame wait

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

The routine first waits until the raster is in the high raster range, then waits until it wraps back to the top of the frame.

This avoids mistaking raster line 256 for raster line 0.

### SPACE key check

The keyboard routine selects the column containing SPACE, then reads the row bit:

```asm
lda #%01111111
sta $dc00

lda $dc01
and #%00010000
beq space_is_pressed
```

Pressed keys read as 0.

Released keys read as 1.

That is why `beq` means SPACE is pressed here.

### Workload

The workload is deliberately artificial:

```asm
do_work:
    ldx #$02
```

It burns CPU time with nested loops.

Changing this value changes the height of the blue timing band.

## The key idea

Lesson 17 introduces measurement.

Instead of only producing an effect, the border now helps us understand how much time a routine takes.

This is important because old machines have strict frame budgets.

If a routine takes too long, the display timing suffers.

The border makes that cost visible.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/17-measuring-raster-time
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

Then hold SPACE.

You should see a blue timing band near the top of the border.

Release SPACE and the border should remain black.

## Machine concepts

This lesson introduces:

- the border as a visual timing profiler
- frame budget thinking
- keyboard matrix input
- CIA #1 port A and port B
- disabling normal IRQ interrupts with `sei`
- why uncontrolled interrupts disturb timing

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- VIC-II border colour register
- VIC-II background colour register
- VIC-II raster high bit in `$d011`
- infinite loop structure
- subroutines
- raster polling

## Assembly concepts

This lesson introduces or reinforces:

- `sei`
- reading CIA registers
- bit masking with `and`
- returning status in A
- state byte for `show_timing`
- nested loops as a controlled workload
- visual measurement of routine cost

It reuses:

- `lda`
- `sta`
- `ldx`
- `ldy`
- `dex`
- `dey`
- `bne`
- `beq`
- `bpl`
- `bmi`
- `jsr`
- `rts`
- `jmp`
- `.byte`

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$d011` | VIC-II control register 1, includes high raster bit |
| `$d012` | VIC-II raster counter low byte, discussed from Lesson 16 |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |
| `$dc00` | CIA #1 port A, keyboard column selection |
| `$dc01` | CIA #1 port B, keyboard row input |

## Experiments

### Change the workload

Change:

```asm
ldx #$02
```

Try:

```asm
ldx #$01
```

The blue band should become shorter.

Then try:

```asm
ldx #$04
```

or:

```asm
ldx #$08
```

The blue band should become taller.

### Remove `sei`

Temporarily remove:

```asm
sei
```

Build and run again.

Watch the timing band while holding SPACE.

You may see more jitter because the normal system IRQ can interrupt the measurement loop.

Put `sei` back afterwards.

### Always show the timing band

Replace the SPACE check with a direct border colour change so the timing band is always visible.

Then put the SPACE check back afterwards.

### Change the timing colour

Change:

```asm
lda #$06
```

before `sta $d020`.

Try other colour values from `$00` to `$0f`.

### Make the work too long

Try:

```asm
ldx #$20
```

The blue band may extend far down the screen or wrap into later frames.

This is useful to see, but it is not the intended default for this lesson.

Put the smaller value back afterwards.

## Common mistakes

### Expecting keyboard input to behave like BASIC

This program disables normal IRQ interrupts.

The normal KERNAL keyboard handling is not what we are using here.

We are reading the keyboard matrix directly through CIA registers.

### Forgetting that pressed keys read as zero

In the C64 keyboard matrix, pressed keys read as 0.

Released keys read as 1.

That is why the code uses:

```asm
beq space_is_pressed
```

after masking the SPACE bit.

### Making the workload too large

If `do_work` takes too long, the blue timing band may extend too far or wrap into the next frame.

Start small.

### Thinking this is perfect timing

This is much cleaner after `sei`, but it is still polling-based timing.

It is not yet a cycle-stable raster interrupt routine.

### Forgetting that `sei` changes system behaviour

With normal IRQs disabled, the system is no longer running its usual interrupt tasks.

That is fine for this controlled lesson, but it is something we must understand.

## What comes next

Next lesson:

```text
18 - First raster bars
```

Now that we can:

```text
wait for frame timing
change the border during the frame
measure work with the border
disable unwanted IRQ jitter
```

we can build something more visual.

The next lesson should create simple raster bars by changing the border colour across several raster lines.

That will be a more recognisable C64 effect and a clear step toward demoscene-style timing.
