# Lesson 31 - Phase-safe dense raster bars

## Goal

In this lesson we move beyond the static raster-bar stack from Lesson 30.

Lesson 30 gave us:

- multiple left-aligned full-width raster bars
- table-driven colours
- self-modifying code to keep the critical colour-on path fast
- a safe, static schedule

Lesson 31 adds two new steps:

- denser bar spacing
- vertical movement

But it does this in a controlled way.

The main idea is:

> Move and place the raster bars while preserving the known-good raster phase.

This is not yet arbitrary smooth movement. It is phase-safe movement.

## What you will build

You will build a C64 program that:

- clears the screen and colour RAM
- installs a stable double raster IRQ
- draws a dense stack of left-aligned full-width raster bars
- uses 8-line spacing between bars
- generates setup lines from a base line and offset table
- moves the whole raster-bar stack vertically
- moves only in 8-line steps to preserve timing phase
- slows the movement with a frame counter
- keeps colour selection outside the critical colour-on path

The visible result is a dense raster-bar stack that moves up and down cleanly.

## What this teaches

Lesson 31 teaches that safe raster scheduling is not only about avoiding badlines.

It is also about preserving the timing phase of the routine.

In earlier tests, some schedules looked safe because the target lines were not badlines. But they still produced visible artefacts because the setup, stable, and target lines were no longer in the same known-good phase as Lesson 30.

The working phase for this routine is:

```text
setup line  & 7 = 4
stable line & 7 = 5
target line & 7 = 6
```

Because the stable IRQ happens one line after the setup IRQ, and the visible target bar line is one line after that:

```text
setup line        = N
stable IRQ line   = N + 1
target bar line   = N + 2
```

With the normal `$d011 = $1b`, badlines occur where:

```text
line & 7 = 3
```

So this phase keeps the setup, stable, and target lines away from the badline phase.

## Machine concepts

- VIC-II raster interrupts
- raster phase
- badline avoidance
- dense raster-bar scheduling
- vertical raster movement
- frame-based movement speed
- PAL raster timing
- critical-path protection

## Assembly concepts

- generated tables
- base value plus offsets
- signed 8-bit movement using wraparound
- frame counters
- movement bounds
- table rebuilding
- self-modifying operand patching
- separating movement logic from critical display logic

## Hardware registers used

| Address | Name | Purpose |
|---|---|---|
| `$d011` | VIC-II control register 1 | Contains the raster high bit and YSCROLL bits |
| `$d012` | Raster line register | Selects the raster line for the interrupt |
| `$d019` | VIC-II interrupt status | Acknowledges pending VIC-II interrupts |
| `$d01a` | VIC-II interrupt enable | Enables VIC-II raster interrupts |
| `$d020` | Border colour | Controls the border colour |
| `$d021` | Background colour 0 | Controls the main screen background colour in the default text screen |
| `$dc0d` | CIA #1 interrupt control | Used to disable CIA #1 interrupts |
| `$dd0d` | CIA #2 interrupt control | Used to disable CIA #2 interrupts |
| `$fffe/$ffff` | Hardware IRQ vector | Points to the active IRQ handler when KERNAL ROM is banked out |
| `$01` | Processor port | Controls memory banking |

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0801` | BASIC loader start |
| `$080d` | Machine code start address |
| `$0400-$07ff` | Screen memory area cleared at startup |
| `$d800-$dbff` | Colour RAM area cleared at startup |
| `$0100-$01ff` | Stack page |
| `$fffe/$ffff` | Hardware IRQ vector |
| `current_bar` | Current bar table index |
| `base_setup_line` | First setup line for the moving stack |
| `move_delta` | Movement direction and step size |
| `move_counter` | Frame counter used to slow movement |
| `setup_offsets` | Offsets from the base setup line |
| `setup_lines` | Generated setup-line table |
| `bar_colour_instruction + 1` | Operand byte patched by self-modifying code |

## From Lesson 30 to Lesson 31

Lesson 30 used wide spacing:

```asm
setup_lines:
    .byte 92
    .byte 116
    .byte 140
    .byte 164
    .byte 188
    .byte $ff
```

That gives 24 raster lines between setup IRQs.

Lesson 31 first moves to dense 8-line spacing:

```asm
setup_lines:
    .byte 92
    .byte 100
    .byte 108
    .byte 116
    .byte 124
    .byte 132
    .byte 140
    .byte 148
    .byte 156
    .byte $ff
```

This works because every setup line has the same lower three bits:

```text
92  & 7 = 4
100 & 7 = 4
108 & 7 = 4
```

So every bar keeps the same timing phase:

```text
setup line  & 7 = 4
stable line & 7 = 5
target line & 7 = 6
```

## Why not move by one line yet?

If we moved the stack by one raster line, the phase would change.

For example:

```text
base setup line = 92  -> 92 & 7 = 4
base setup line = 93  -> 93 & 7 = 5
base setup line = 94  -> 94 & 7 = 6
```

That would no longer preserve the known-good phase.

So Lesson 31 moves only in 8-line steps:

```text
92 -> 100 -> 108 -> 116 -> 124
```

Adding or subtracting 8 keeps the lower three bits unchanged.

That means the movement is not smooth yet, but it is safe and stable.

The next lesson can attack the harder problem: smooth movement across changing phases.

## Generated setup lines

Instead of manually writing every setup line, Lesson 31 uses:

```asm
base_setup_line:
    .byte 92
```

and an offset table:

```asm
setup_offsets:
    .byte 0
    .byte 8
    .byte 16
    .byte 24
    .byte 32
    .byte 40
    .byte 48
    .byte 56
    .byte 64
    .byte $ff
```

The routine `rebuild_setup_lines` combines these:

```text
setup line = base setup line + offset
```

So when `base_setup_line` is 92, the generated setup lines are:

```text
92, 100, 108, 116, 124, 132, 140, 148, 156
```

When `base_setup_line` moves to 100, the generated setup lines are:

```text
100, 108, 116, 124, 132, 140, 148, 156, 164
```

The shape of the stack stays the same. Only its vertical position changes.

## Movement

Movement is controlled by three bytes:

```asm
base_setup_line:
    .byte 92

move_delta:
    .byte $08

move_counter:
    .byte 0
```

`move_delta` is either:

```text
$08 = move down by 8 raster lines
$f8 = move up by 8 raster lines
```

`$f8` represents `-8` in 8-bit wraparound arithmetic.

The movement bounces between base setup lines 92 and 124.

## Movement speed

The movement is slowed by `move_counter`.

The final Lesson 31 version uses:

```asm
cmp #$10
```

This means:

> Move once every 16 completed frames.

At PAL speed, this gives a slow, calm movement that is easier to observe.

Earlier test values were:

```text
#$04 - faster movement
#$08 - medium movement
#$10 - slower movement
```

This does not make the motion truly smooth. It only makes the 8-line steps slower.

True smoothness requires smaller movement steps, which changes the raster phase and must be solved later.

## Why the movement update is outside the critical path

The movement update happens only after the last bar in the stack has been drawn.

That means it is far away from the colour-on critical moment.

The critical colour-on path remains:

```asm
bar_colour_instruction:
    lda #$06
    sta $d020
    sta $d021
```

The colour value is still patched before the bar is drawn, as in Lesson 30.

Movement logic, table rebuilding, and colour patching are all kept away from the cycle-critical colour-on write.

## Code walkthrough

### BASIC loader

The program starts with the usual BASIC loader:

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

This creates:

```basic
10 SYS 2061
```

`2061` decimal is `$080d`, where the machine code starts.

### Initial setup

The program disables interrupts:

```asm
sei
```

It banks out BASIC and KERNAL ROM while keeping I/O visible:

```asm
lda #$35
sta $01
```

It sets the border and background to black:

```asm
lda #$00
sta $d020
sta $d021
```

Then it clears screen memory and colour RAM so the raster bars are not visually disturbed by BASIC text.

### Building the initial setup table

The current bar index is reset:

```asm
lda #$00
sta current_bar
```

Then the generated setup-line table is built:

```asm
jsr rebuild_setup_lines
```

The first colour is patched into the immediate colour instruction:

```asm
ldx current_bar
lda bar_colours,x
sta bar_colour_instruction + 1
```

Then the first setup line is loaded from `setup_lines`.

### The setup IRQ

The setup IRQ is the first half of the double IRQ pattern.

It saves A, X, and Y, installs the stable IRQ handler, moves `$d012` to the next raster line, acknowledges the first interrupt, saves the stack pointer with `tsx`, re-enables interrupts, and waits in predictable `nop` instructions.

The stable IRQ then interrupts this predictable wait area.

### The stable IRQ

The stable IRQ restores the stack pointer with:

```asm
txs
```

Then it runs the stabilisation sequence:

```asm
ldx #$08

stable_delay:
    dex
    bne stable_delay

bit $00

lda $d012
cmp $d012

beq stable_point
```

The branch to the next instruction provides the final one-cycle correction.

### The critical colour-on path

The colour-on path is:

```asm
bar_colour_instruction:
    lda #$06
    sta $d020
    sta $d021
```

The operand of `lda #$06` is patched before each bar.

This keeps the critical path as fast as the hard-coded version while still allowing the bar colours to come from a table.

### Holding and turning off the bar

The bar is held to the right-side position:

```asm
ldx #$08

bar_hold:
    dex
    bne bar_hold

nop
```

Then it remains active for one PAL raster line:

```asm
ldx #$0c

one_line_delay:
    dex
    bne one_line_delay

nop
```

Then the colours are restored to black:

```asm
lda #$00
sta $d020
sta $d021
```

### Scheduling the next bar

The current bar index is advanced.

If the next setup-line entry is not `$ff`, the next bar is scheduled.

If the entry is `$ff`, the stack has finished for this frame. The program then:

```asm
jsr update_bar_movement
jsr rebuild_setup_lines
```

Then it wraps back to the first bar.

This means movement and table rebuilding happen once per completed stack.

## What you should see

You should see a dense raster-bar stack that moves up and down.

The movement should be slow because the final version uses:

```asm
cmp #$10
```

The bars should remain clean because movement happens in 8-line steps and preserves the known-good phase.

The success criteria are:

- dense raster bars
- left-aligned full-width bars
- no visible flicker
- table-driven colours
- generated setup-line table
- vertical movement
- phase preserved during movement

## Experiments

### 1. Change movement speed

Change:

```asm
cmp #$10
```

to:

```asm
cmp #$08
```

or:

```asm
cmp #$04
```

The movement becomes faster.

### 2. Change movement bounds

Change the bounce limits:

```asm
cmp #124
```

and:

```asm
cmp #92
```

This changes how far the stack travels.

Keep the base setup line values phase-safe:

```text
base_setup_line & 7 = 4
```

### 3. Break the phase deliberately

Change:

```asm
base_setup_line:
    .byte 92
```

to:

```asm
base_setup_line:
    .byte 93
```

This changes the phase.

The result may show artefacts, because the setup/stable/target lines are no longer in the known-good phase.

### 4. Try one-line movement

Change:

```asm
move_delta:
    .byte $08
```

to:

```asm
move_delta:
    .byte $01
```

This is expected to cause problems.

That is the point.

It demonstrates why smooth movement is harder than phase-safe movement.

### 5. Change the colour ramp

Try another symmetric ramp:

```asm
bar_colours:
    .byte $02
    .byte $08
    .byte $0a
    .byte $07
    .byte $01
    .byte $07
    .byte $0a
    .byte $08
    .byte $02
```

## Common mistakes

### Thinking 8-line movement is smooth movement

It is not.

It is phase-safe movement.

It preserves timing, but the movement is chunky.

### Thinking badline-safe means phase-safe

Avoiding badlines is necessary, but it is not the full rule.

For this routine, the setup, stable, and target lines must preserve the known-good phase.

### Updating movement inside the critical path

Movement logic must not be placed before the colour-on write.

It belongs after the stack is complete.

### Forgetting to rebuild the setup table

Changing `base_setup_line` alone does not move the bars.

The generated `setup_lines` table must be rebuilt.

### Letting the generated table overflow too far

All setup lines in this version are below 256.

If later movement goes beyond 255, we must also handle the high raster bit in `$d011`.

That is not part of this lesson.

## How to build

From the lesson folder:

```sh
./build.sh
```

The build script assembles the program with KickAssembler and starts it in VICE x64sc.

## How to run

After building, VICE should open automatically.

If it does not, you can run the generated program manually in VICE.

The BASIC loader starts the machine code with:

```basic
SYS 2061
```

## What comes next

Lesson 32 should stop playing safe.

The next problem is:

> What happens when we try to move the raster bars smoothly, one line at a time?

That will break the known-good phase.

The next step is therefore:

```text
phase-safe movement -> phase-aware movement
```

Lesson 32 should deliberately introduce the problem and begin solving it, rather than avoiding it.
