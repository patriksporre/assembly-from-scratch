# Lesson 29 - Left-aligned raster bar

## Goal

In this lesson we solve the next raster-bar problem:

> The bar is stable, but it starts too far to the right.

Lesson 27 gave us one stable full-width pulse.

Lesson 28 gave us several stable scheduled pulses, but the visible colour writes happened after IRQ entry, stabilisation, and table lookup. That meant the bars were stable, but horizontally late.

Lesson 29 introduces a new strategy:

> Turn the colour on before the target line begins.

Instead of trying to start the bar at the left edge from inside the same line, we turn the colour on late on the previous raster line, keep it active for one full raster line, then turn it off near the same horizontal position one line later.

This makes the target raster line begin with the colour already active.

## What you will build

You will build a C64 program that:

- installs a stable double raster IRQ
- turns the border and background blue late on one raster line
- keeps the colour active for one full PAL raster line
- turns the colour black again on the following line
- repeats the effect every frame

The visible result is a stable, left-aligned, full-width raster bar.

## What this teaches

This lesson teaches that stable timing and horizontal alignment are different problems.

A stable IRQ gives us a reliable cycle position.

But that position may still be too late in the line.

To make the target line begin blue from the left side, the colour must already be blue before that line begins.

This lesson also introduces an important PAL timing fact:

```text
One PAL C64 raster line = 63 CPU cycles
```

We use that to delay from one horizontal position to approximately the same horizontal position on the next raster line.

## Machine concepts

- VIC-II raster interrupts
- stable double IRQ timing
- border colour
- background colour
- PAL raster line length
- horizontal alignment
- line-to-line timing
- full-width raster bars

## Assembly concepts

- double IRQ stabilisation
- stack pointer control with `tsx` and `txs`
- timing delay loops
- fixed-cycle padding with `nop`
- 63-cycle PAL line delay
- restoring IRQ state for the next frame

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
| `$0100-$01ff` | Stack page |
| `$fffe/$ffff` | Hardware IRQ vector |

## Main idea

The setup is:

```text
setup line      = 92
stable IRQ line = 93
target bar line = 94
```

The colour is turned on late on line 93.

Line 94 then begins with the colour already active.

After one full PAL raster line delay, the colour is turned off late on line 94.

So the visible structure is:

```text
line 93 - colour turns on late
line 94 - full line begins blue and stays blue until the right-side restore point
```

The small late segment on line 93 may be visible as a tail, but in the tested result it is small enough not to matter visually.

## Why Lesson 28 started too far right

In Lesson 28, the stable IRQ happened on the same line where the bar was drawn.

Before the visible colour writes, the CPU had to perform:

- IRQ entry
- stack handling
- second IRQ entry
- `txs`
- stabilisation delay
- raster compare correction
- table lookup
- colour load

Only then did the code reach:

```asm
sta $d020
sta $d021
```

By that time, the raster beam had already moved horizontally into the line.

That made the bars stable, but too far to the right.

## Why Lesson 29 starts correctly

Lesson 29 changes the timing strategy.

Instead of trying to turn the colour on at the start of the target line, it turns the colour on before the target line begins.

That means the next line starts with the colour already active.

This is the important shift:

```text
Lesson 28: turn colour on during the target line
Lesson 29: turn colour on before the target line
```

## The 63-cycle line delay

On a PAL C64, one raster line is 63 CPU cycles.

This delay is designed to take 63 cycles:

```asm
ldx #$0c

one_line_delay:
    dex
    bne one_line_delay

nop
```

Cycle count:

```text
ldx #$0c                  2 cycles
11 taken loops * 5        55 cycles
final dex/bne exit        4 cycles
nop                       2 cycles
--------------------------------
total                     63 cycles
```

That brings execution to approximately the same horizontal position on the next raster line.

This is PAL-specific.

NTSC machines have different cycles per line, so this exact delay is not portable across C64 video standards.

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

The program disables IRQs:

```asm
sei
```

It banks out BASIC and KERNAL ROM while keeping I/O visible:

```asm
lda #$35
sta $01
```

This lets the program write directly to the hardware IRQ vector at `$fffe/$ffff`.

The colours are set to black:

```asm
lda #$00
sta $d020
sta $d021
```

CIA interrupts are disabled:

```asm
lda #%01111111
sta $dc0d

lda #%01111111
sta $dd0d
```

Pending CIA interrupts are acknowledged:

```asm
lda $dc0d
lda $dd0d
```

The setup IRQ handler is installed:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff
```

The first raster line is selected:

```asm
lda #setup_line
sta $d012
```

The raster high bit is cleared because the line is below 256:

```asm
lda $d011
and #$7f
sta $d011
```

The VIC-II raster interrupt is acknowledged and enabled:

```asm
lda #%00000001
sta $d019

lda #%00000001
sta $d01a
```

Then IRQs are enabled:

```asm
cli
```

The main program loops forever while the IRQ handlers do the visible work.

## The setup IRQ

The setup IRQ fires on line 92.

It saves the registers:

```asm
pha

txa
pha

tya
pha
```

It installs the stable IRQ handler:

```asm
lda #<irq_stable
sta $fffe

lda #>irq_stable
sta $ffff
```

It moves the raster interrupt to the next line:

```asm
inc $d012
```

So the stable IRQ fires on line 93.

It acknowledges the first raster interrupt:

```asm
lda #%00000001
sta $d019
```

It saves the current stack pointer in `X`:

```asm
tsx
```

Then it enables interrupts again:

```asm
cli
```

The second IRQ will interrupt while the first IRQ is waiting in predictable `nop` instructions.

## The stable IRQ

The stable IRQ begins with:

```asm
txs
```

This restores the stack pointer saved by `irq_setup`.

That discards the second IRQ's own return frame, allowing this handler to finish the original interrupt path.

Then the stabilisation sequence runs:

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

The `bit $00` instruction is used as a 3-cycle delay.

The `$d012` compare and branch performs the final one-cycle correction.

The branch target is the next instruction, so both paths continue at the same place, but with either a 2-cycle or 3-cycle branch cost.

## Turning the colour on

At the stable point, the colour is turned on:

```asm
stable_point:
    lda #$06
    sta $d020
    sta $d021
```

This happens late on line 93.

The target line is line 94.

So this colour change is preparation for the next line.

## Holding the colour to the right-side position

The first delay keeps the colour active until the desired right-side timing position:

```asm
ldx #$08

bar_hold:
    dex
    bne bar_hold

nop
```

This is the same coarse-plus-fine timing introduced in Lesson 27.

In Lesson 27, this was where we restored the colour.

In Lesson 29, we do not restore yet.

We keep the colour active.

## Waiting one full raster line

The next delay waits one full PAL raster line:

```asm
ldx #$0c

one_line_delay:
    dex
    bne one_line_delay

nop
```

This takes 63 cycles on PAL.

The result is that the code reaches approximately the same horizontal position on the next raster line.

## Turning the colour off

After the one-line delay, the colour is restored to black:

```asm
lda #$00
sta $d020
sta $d021
```

This happens late on line 94.

Because the colour was already active when line 94 began, the target line appears left-aligned.

## Restoring the IRQ for the next frame

The setup IRQ is restored:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff
```

The setup line is restored:

```asm
lda #setup_line
sta $d012
```

The raster high bit is cleared:

```asm
lda $d011
and #$7f
sta $d011
```

The raster interrupt is acknowledged:

```asm
lda #%00000001
sta $d019
```

The registers saved by the setup IRQ are restored:

```asm
pla
tay

pla
tax

pla
```

Then the interrupt returns:

```asm
rti
```

Because `txs` discarded the second IRQ return frame, this `rti` returns from the original first interrupt.

## What you should see

You should see a stable blue full-width raster bar.

The target line should begin blue from the left side and remain blue across the visible width.

Depending on exact timing and display, you may see a tiny blue segment near the end of the previous line. That is expected.

The success criteria are:

- stable position
- no flicker
- blue begins at the left side of the target line
- blue reaches the right side cleanly
- timing is achieved through a PAL 63-cycle line delay

## Experiments

### 1. Remove the one-line delay

Remove or comment out:

```asm
ldx #$0c

one_line_delay:
    dex
    bne one_line_delay

nop
```

The colour will be restored too early.

This shows why the line delay is needed.

### 2. Change the line delay

Try changing:

```asm
ldx #$0c
```

to:

```asm
ldx #$0b
```

or:

```asm
ldx #$0d
```

The restore position should move because the delay is no longer exactly one PAL line.

### 3. Remove the fine-tuning `nop`

Remove the `nop` after `bar_hold`.

This should slightly change the right edge.

### 4. Change the colour

Change:

```asm
lda #$06
```

to another colour, such as:

```asm
lda #$03
```

This makes the bar cyan.

### 5. Move the setup line

Change:

```asm
.const setup_line = 92
```

to another safe setup line.

Remember:

```text
stable IRQ line = setup line + 1
target line     = setup line + 2
```

Avoid badlines for now.

With `$d011 = $1b`, badlines occur where:

```text
line & 7 = 3
```

## Common mistakes

### Thinking the IRQ line is the target line

In this lesson, the stable IRQ line is not the full target line.

The stable IRQ line is where we turn the colour on.

The target line is the following line.

### Forgetting that this is PAL-specific

The 63-cycle delay is correct for PAL C64 timing.

It is not correct for NTSC C64 timing.

### Thinking the previous-line tail is a bug

A small segment on the previous line is expected because the colour is turned on before the target line begins.

The important result is that the target line starts blue from the left side.

### Thinking left-aligned means final-perfect

This lesson solves left alignment for one bar.

It does not yet solve:

- multiple left-aligned bars
- badline compensation
- dense bars
- animation
- sine movement
- PAL/NTSC abstraction

Those come later.

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

Lesson 30 should apply this left-aligned method to multiple bars.

The next goal is:

```text
one left-aligned bar -> multiple left-aligned bars
```

We will keep avoiding badlines at first.

Then we can move toward:

- badline-aware scheduling
- denser bars
- colour tables
- movement
- sine-controlled raster-bar positions

The destination remains perfect, demo-ready raster bars.
