# Lesson 26 - Stable raster IRQ and badline awareness

## Goal

In this lesson we create a more stable raster interrupt timing marker on the Commodore 64.

Earlier raster interrupt lessons let us choose a raster line, but they did not give us a predictable cycle inside that line.

That distinction matters.

A raster interrupt tells the CPU:

> Run this interrupt handler when the raster beam reaches this line.

But the CPU does not always enter the handler at exactly the same cycle within that line.

This lesson introduces the classic double raster interrupt pattern used to reduce that timing uncertainty.

## What you will build

You will build a small C64 program that:

- installs a raster interrupt
- uses a first IRQ to set up a second IRQ on the following raster line
- lets the second IRQ interrupt predictable `nop` instructions
- applies a final timing correction
- draws a short blue timing marker in the border using `$d020`

This lesson only changes the border colour.

It does not change the background colour.

That is deliberate.

We are testing stable horizontal timing before we try to draw full-width raster bars.

## Why this lesson exists

Raster effects are not only about choosing the right raster line.

They are also about choosing the right cycle on that line.

If the interrupt handler starts a few cycles earlier or later each frame, colour changes will move horizontally. That creates unstable or shimmering raster effects.

A normal raster IRQ has timing jitter because the CPU may be executing different instructions when the interrupt request arrives.

The interrupt cannot fully begin until the current instruction has finished.

That means the handler may start at slightly different cycle positions.

The double IRQ pattern reduces this problem.

## The two different timing problems

This lesson separates two problems that are easy to mix together.

### 1. IRQ jitter

IRQ jitter means the interrupt handler does not start at exactly the same cycle every frame.

This is caused by the CPU finishing whatever instruction it was already executing when the IRQ arrived.

Different instructions take different numbers of cycles.

The double IRQ pattern helps reduce this jitter.

### 2. Badline disruption

Badline disruption is different.

A badline happens when the VIC-II needs to fetch character data for a new row of text.

On those lines, the VIC-II steals many cycles from the CPU.

That means the CPU has fewer cycles available on that raster line.

Even if the interrupt timing is stable, badlines can still delay code that runs on the line.

This matters later when we want to change both:

- `$d020` - border colour
- `$d021` - background colour

A stable IRQ alone does not automatically make a clean full-width raster bar.

## The double IRQ pattern

This lesson uses two interrupt handlers.

### First IRQ - setup IRQ

The first IRQ happens on `setup_line`.

It does not draw the visible marker.

Its job is to:

1. save the registers
2. install the second IRQ handler
3. move the raster interrupt to the next line
4. acknowledge the first raster interrupt
5. save the current stack pointer with `tsx`
6. re-enable interrupts with `cli`
7. wait using predictable 2-cycle `nop` instructions

The important part is the wait area.

The second IRQ should interrupt the first handler while the CPU is executing `nop` instructions.

Since each `nop` takes 2 cycles, the remaining timing variation is much smaller.

### Second IRQ - stable IRQ

The second IRQ interrupts the first IRQ.

It then:

1. restores the stack pointer with `txs`
2. performs a timed delay
3. uses a raster compare correction
4. draws the blue border marker
5. restores the first IRQ for the next frame
6. restores the saved registers
7. returns with `rti`

The `txs` instruction is important.

The second IRQ creates another interrupt return frame on the stack. We do not want to return to the middle of the first IRQ's wait code.

By restoring the stack pointer saved by the first IRQ, the second IRQ discards the extra interrupt frame and returns from the original first interrupt cleanly.

## What this teaches

This lesson teaches:

- why raster IRQs are not automatically cycle-stable
- why the CPU's current instruction affects IRQ entry timing
- how a double IRQ reduces timing uncertainty
- why `nop` is useful for predictable timing
- how `tsx` and `txs` are used to control the stack
- why badlines are a separate problem from IRQ jitter
- why stable timing must be proven before drawing more complex effects

## Machine concepts

- VIC-II raster interrupts
- IRQ vectors
- raster line selection
- cycle timing
- badlines
- border colour changes
- CPU and VIC-II bus sharing

## Assembly concepts

- interrupt handlers
- saving and restoring registers
- stack pointer control
- `tsx`
- `txs`
- `nop`
- timing loops
- branch timing
- `rti`

## Hardware registers used

| Address | Name | Purpose |
|---|---|---|
| `$d011` | VIC-II control register 1 | Contains the high bit of the raster line and display control bits |
| `$d012` | Raster line register | Selects the raster line for the interrupt |
| `$d019` | VIC-II interrupt status | Acknowledges pending VIC-II interrupts |
| `$d01a` | VIC-II interrupt enable | Enables VIC-II raster interrupts |
| `$d020` | Border colour | Used to draw the visible timing marker |
| `$d021` | Background colour | Set to black at startup only |
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

This lesson banks out BASIC and KERNAL ROM with:

```asm
lda #$35
sta $01
```

This keeps I/O visible while allowing the program to write directly to the hardware IRQ vector at `$fffe/$ffff`.

## Routine documentation

### `irq_setup`

Input:

- none

Output:

- second IRQ set up on `setup_line + 1`

Destroys:

- handled by the second IRQ path

Preserves:

- restored by the second IRQ path

Memory used:

- stack page `$0100-$01ff`

### `irq_stable`

Input:

- `X` - stack pointer saved by `irq_setup`

Output:

- stable blue border marker drawn
- next setup IRQ installed for the next frame

Destroys:

- none, after restoration

Preserves:

- `A`
- `X`
- `Y`
- flags are restored by `rti`

Memory used:

- stack page `$0100-$01ff`

## Code walkthrough

### BASIC loader

The program starts with a small BASIC loader:

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

This creates a BASIC line equivalent to:

```basic
10 SYS 2061
```

`2061` decimal is `$080d` hexadecimal, where the machine code starts.

### Initial setup

The program begins by disabling IRQs:

```asm
sei
```

This prevents an interrupt from firing while we are changing interrupt vectors and hardware registers.

The program then banks out BASIC and KERNAL ROM:

```asm
lda #$35
sta $01
```

This makes the hardware IRQ vector at `$fffe/$ffff` writable.

The border and background are set to black:

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

This keeps the lesson focused on VIC-II raster interrupts only.

Any pending CIA interrupts are acknowledged by reading the interrupt control registers:

```asm
lda $dc0d
lda $dd0d
```

### Installing the first IRQ

The first interrupt handler is installed at `$fffe/$ffff`:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff
```

The raster line is selected:

```asm
lda #setup_line
sta $d012
```

Because the selected line is below 256, the high raster bit in `$d011` is cleared:

```asm
lda $d011
and #$7f
sta $d011
```

Then raster interrupts are acknowledged and enabled:

```asm
lda #%00000001
sta $d019

lda #%00000001
sta $d01a
```

Finally, IRQs are enabled again:

```asm
cli
```

The main program then loops forever:

```asm
main_loop:
    jmp main_loop
```

The visible work is now done by the interrupt handlers.

## The setup IRQ

The first IRQ saves the registers:

```asm
pha

txa
pha

tya
pha
```

It then installs the second IRQ handler:

```asm
lda #<irq_stable
sta $fffe

lda #>irq_stable
sta $ffff
```

The next raster interrupt is moved to the following line:

```asm
inc $d012
```

The first raster interrupt is acknowledged:

```asm
lda #%00000001
sta $d019
```

Then the stack pointer is saved in `X`:

```asm
tsx
```

This is an important part of the double IRQ method.

The second IRQ will create another interrupt frame on the stack. Later, `irq_stable` will use `txs` to restore this saved stack position.

The first IRQ then enables interrupts again:

```asm
cli
```

This allows the second IRQ to interrupt the first IRQ.

Then it waits with predictable 2-cycle instructions:

```asm
nop
nop
nop
```

The goal is for the second IRQ to arrive while the CPU is executing these `nop` instructions.

## The stable IRQ

The second IRQ starts by restoring the stack pointer:

```asm
txs
```

This discards the extra interrupt frame created by the second IRQ.

Then a small timing delay runs:

```asm
ldx #$08

stable_delay:
    dex
    bne stable_delay
```

The code then performs a final correction:

```asm
bit $00

lda $d012
cmp $d012

beq stable_point
```

The `beq` branches to the next instruction.

A branch takes:

- 3 cycles when taken
- 2 cycles when not taken

This one-cycle difference is used to correct the final timing uncertainty.

Then the visible marker is drawn:

```asm
stable_point:
    lda #$06
    sta $d020
```

The marker is held for a short time:

```asm
ldx #$10

marker_hold:
    dex
    bne marker_hold
```

Then the border is returned to black:

```asm
lda #$00
sta $d020
```

The first IRQ is restored for the next frame:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff

lda #setup_line
sta $d012
```

The raster high bit is cleared again:

```asm
lda $d011
and #$7f
sta $d011
```

The second raster interrupt is acknowledged:

```asm
lda #%00000001
sta $d019
```

Finally, the saved registers are restored:

```asm
pla
tay

pla
tax

pla
```

And the interrupt returns:

```asm
rti
```

This returns from the original first IRQ path, because the second IRQ's extra stack frame was discarded with `txs`.

## What you should see

You should see a stable blue timing marker in the border.

The marker may appear as small blue pieces in the left and right border.

For example, you may see two small blue pieces on the left border and one on the right.

That is acceptable.

This lesson is not trying to draw a full-width raster bar.

It is only testing whether the timing marker is horizontally stable from frame to frame.

The success criterion is:

> The marker should be stable. It should not shimmer, crawl, or jump horizontally.

## Why the marker is not a full raster bar

A full raster bar needs both the border and the screen area to change colour cleanly.

That means controlling both:

```asm
$d020 - border colour
$d021 - background colour
```

This lesson only changes `$d020`.

That means we are only observing the border timing.

The next lesson will build on this foundation and attempt proper full-width raster bars.

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

## Experiments

### 1. Change the marker colour

Find:

```asm
lda #$06
sta $d020
```

Try another colour value.

For example:

```asm
lda #$02
sta $d020
```

This should make the marker red.

### 2. Change the marker length

Find:

```asm
ldx #$10
```

Try a smaller or larger value.

A larger value keeps the blue marker visible for more cycles.

A smaller value makes it shorter.

### 3. Move the setup line

Find:

```asm
.const setup_line = 92
```

Try another raster line.

Avoid drawing conclusions too quickly if you move near badlines.

Some lines are more complicated because the VIC-II may steal CPU cycles.

### 4. Break the stabilisation deliberately

Remove or reduce some of the `nop` instructions in `irq_setup`.

The marker may become unstable or disappear if the second IRQ no longer arrives during the predictable wait area.

This helps show why the wait area exists.

### 5. Change the timing delay

Find:

```asm
ldx #$08
```

Try nearby values.

The marker should move horizontally.

This shows that timing on a raster line is cycle-positioned.

## Common mistakes

### Expecting a full raster bar

This lesson is not a raster bar lesson.

It only changes `$d020`, the border colour.

The screen background colour `$d021` is not changed during the marker.

### Confusing IRQ jitter with badlines

A stable IRQ fixes one problem: interrupt entry timing.

It does not remove VIC-II bus stealing on badlines.

Badlines still matter.

### Forgetting to acknowledge the raster interrupt

If `$d019` is not acknowledged, the interrupt may immediately fire again or behave incorrectly.

The raster interrupt is acknowledged by writing bit 0:

```asm
lda #%00000001
sta $d019
```

### Returning from the wrong interrupt frame

The second IRQ interrupts the first IRQ.

That creates an extra interrupt return frame on the stack.

The `txs` instruction restores the stack pointer saved by the first IRQ, so the final `rti` returns from the original interrupt path.

Removing this will break the logic.

### Using too few NOPs

The first IRQ must wait long enough for the second IRQ to arrive.

If the `nop` area is too short, execution may fall into `setup_wait`.

That should not happen during normal operation.

## What comes next

Lesson 27 will use this stable IRQ foundation to draw proper full-width raster bars.

That means changing both:

```asm
$d020 - border colour
$d021 - background colour
```

The important next step is to place those writes deliberately and avoid or account for badlines.

We should not call the result a proper full-width raster bar unless the colour change is clean across:

- left border
- screen area
- right border
```
