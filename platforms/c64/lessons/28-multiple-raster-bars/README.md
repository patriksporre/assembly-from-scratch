# Lesson 28 - Multiple raster bars on safe lines

## Goal

In this lesson we move from one full-width raster pulse to several stable raster pulses.

Lesson 27 proved that we can create one full-width pulse by changing both:

```asm
$d020 - border colour
$d021 - background colour
```

Lesson 28 adds a new problem:

> How do we schedule several raster interrupts without causing flicker or missed bars?

The answer in this lesson is simple and deliberate:

> Choose safe non-badlines, and leave enough vertical space between scheduled interrupts.

This lesson does not try to make dense raster bars yet.

It creates several stable scheduled bars and documents the limits we have discovered.

## What you will build

You will build a C64 program that:

- uses the stable double IRQ pattern from Lesson 26 and Lesson 27
- draws one full-width raster pulse per stable IRQ
- schedules the next bar from a table
- uses selected non-badline raster positions
- spaces the bars far enough apart that each interrupt has time to finish
- repeats the sequence every frame

The visible result is a small stack of stable full-width raster pulses.

## What this teaches

This lesson teaches that multiple raster bars are not only a drawing problem.

They are also a scheduling problem.

A raster interrupt handler takes time. It must:

- enter the IRQ
- stabilise timing
- draw the visible pulse
- restore colours
- find the next table entry
- install the next IRQ
- acknowledge the current IRQ
- restore registers
- return with `rti`

If the next raster interrupt is scheduled too close to the current one, the raster beam may already have passed that line before the handler has finished.

That causes flicker, missing bars, or bars appearing only sometimes.

The key lesson is:

> A chained raster IRQ must schedule the next interrupt far enough ahead.

## Machine concepts

- VIC-II raster interrupts
- double IRQ stabilisation
- border colour and background colour
- safe raster lines
- badline avoidance
- interrupt scheduling
- missed raster interrupts
- visible flicker from missed timing

## Assembly concepts

- indexed table lookup
- table terminator
- current index variable
- chaining interrupt handlers
- wrapping a table back to the first entry
- coarse timing with loops
- fine timing with `nop`

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
| `current_bar` | Stores the current table index |

`current_bar` lives in normal program memory, not zero page.

That keeps the lesson simple and avoids introducing new zero-page usage.

## The important difference from Lesson 27

Lesson 27 used one fixed setup line:

```asm
.const setup_line = 92
```

Lesson 28 uses a table:

```asm
setup_lines:
    .byte 92
    .byte 108
    .byte 124
    .byte 140
    .byte 156
    .byte 172
    .byte $ff
```

Each entry is a setup IRQ line.

The visible stable IRQ happens on:

```text
setup line + 1
```

So the visible bar lines are:

```text
93, 109, 125, 141, 157, 173
```

These are spaced 16 raster lines apart.

That spacing is deliberate.

## Why the first attempt flickered

A tighter first attempt used setup lines such as:

```asm
setup_lines:
    .byte 92
    .byte 96
    .byte 100
    .byte 104
    .byte 108
    .byte 112
    .byte $ff
```

Those setup lines are only 4 raster lines apart.

That was too close for our current explicit teaching handler.

By the time one handler had finished drawing, scheduling the next bar, restoring registers, and returning, the raster beam could already have passed the next setup line.

When that happens, the next raster interrupt does not occur at that position in the current frame.

It waits until the raster reaches that line again in the next frame.

That creates flicker.

This is not random behaviour.

It is the machine showing us that timing includes the whole handler, not just the visible colour writes.

## Badline awareness

With the normal `$d011` value of `$1b`, YSCROLL is 3.

That means badlines occur where:

```text
raster line & 7 = 3
```

The visible stable lines in this lesson are:

```text
93, 109, 125, 141, 157, 173
```

Each of those has:

```text
line & 7 = 5
```

So none of them are badlines.

This lesson avoids badlines deliberately.

We are not yet compensating for badlines.

That comes later.

## Why the bars start too far to the right

In the final result, the bars are stable, but they start too far to the right.

That is expected at this stage.

The colour write does not happen immediately when the raster interrupt line begins.

Before the visible write, the CPU must perform:

- IRQ entry
- stack work
- second IRQ entry
- `txs`
- stabilisation delay
- raster compare correction
- table lookup
- colour load

Only then does it reach:

```asm
sta $d020
sta $d021
```

By that time, the raster beam has already moved horizontally into the line.

So the bars are stable, but not left-edge aligned.

This is an important limitation of Lesson 28.

The next lesson will address horizontal alignment deliberately.

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

This creates a BASIC line equivalent to:

```basic
10 SYS 2061
```

`2061` decimal is `$080d` hexadecimal, where the machine code starts.

### Initial setup

The program disables IRQs:

```asm
sei
```

Then it banks out BASIC and KERNAL ROM while keeping I/O visible:

```asm
lda #$35
sta $01
```

The border and background are set to black:

```asm
lda #$00
sta $d020
sta $d021
```

The bar table index is reset:

```asm
lda #$00
sta current_bar
```

CIA interrupts are disabled:

```asm
lda #%01111111
sta $dc0d

lda #%01111111
sta $dd0d
```

Any pending CIA interrupts are acknowledged:

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

The first raster line is loaded from the table:

```asm
ldx current_bar
lda setup_lines,x
sta $d012
```

The high raster bit is cleared because all lines are below 256:

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

Finally, IRQs are enabled:

```asm
cli
```

The main program then loops forever:

```asm
main_loop:
    jmp main_loop
```

The interrupt handlers do the visible work.

## The setup IRQ

The setup IRQ is the first half of the double IRQ pattern.

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

It moves the raster interrupt to the following line:

```asm
inc $d012
```

It acknowledges the first raster interrupt:

```asm
lda #%00000001
sta $d019
```

It saves the stack pointer in `X`:

```asm
tsx
```

Then it enables interrupts again:

```asm
cli
```

Finally, it waits in predictable `nop` instructions:

```asm
nop
nop
nop
...
```

The second IRQ should interrupt this predictable wait area.

## The stable IRQ

The stable IRQ begins by restoring the stack pointer:

```asm
txs
```

This discards the second IRQ return frame.

Then it performs the same stabilisation sequence used in Lesson 27:

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

The branch either takes 3 cycles or 2 cycles.

Since the branch target is the next instruction, both paths continue at the same code location, but with a one-cycle timing correction.

## Drawing one bar

At the stable point, the handler loads the current colour from the table:

```asm
ldx current_bar
lda bar_colours,x
```

Then it writes both the border and background colour registers:

```asm
sta $d020
sta $d021
```

The colour is held with the same coarse-plus-fine timing from Lesson 27:

```asm
ldx #$08

bar_hold:
    dex
    bne bar_hold

nop
```

Then both colours are restored to black:

```asm
lda #$00
sta $d020
sta $d021
```

## Scheduling the next bar

The handler then advances the table index:

```asm
ldx current_bar
inx
```

It checks whether the next setup line is the terminator:

```asm
lda setup_lines,x
cmp #$ff
bne store_next_bar
```

If the next value is `$ff`, the table has ended and the index wraps back to zero:

```asm
ldx #$00
lda setup_lines,x
```

The next bar index is stored:

```asm
store_next_bar:
    stx current_bar
```

Then the setup IRQ is restored:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff
```

The next setup line is installed:

```asm
lda setup_lines,x
sta $d012
```

Finally, the raster interrupt is acknowledged and the saved registers are restored:

```asm
lda #%00000001
sta $d019

pla
tay

pla
tax

pla

rti
```

## Data

The current bar index is stored here:

```asm
current_bar:
    .byte 0
```

The setup lines are stored here:

```asm
setup_lines:
    .byte 92
    .byte 108
    .byte 124
    .byte 140
    .byte 156
    .byte 172
    .byte $ff
```

The terminator `$ff` marks the end of the table.

The colours are stored here:

```asm
bar_colours:
    .byte $06
    .byte $0e
    .byte $03
    .byte $01
    .byte $03
    .byte $0e
```

There is one colour for each setup line.

## What you should see

You should see six stable full-width raster pulses.

They should be spaced vertically.

They should not flicker heavily.

They may start too far to the right.

That is expected for this lesson.

The success criteria are:

- the bars are stable
- the sequence repeats every frame
- the bars are scheduled from a table
- the spacing avoids missed interrupts
- the selected visible lines avoid badlines

The success criterion is not yet:

- perfect left-edge alignment
- dense raster bars
- badline compensation

Those come later.

## Experiments

### 1. Make the bars too close again

Try this table:

```asm
setup_lines:
    .byte 92
    .byte 96
    .byte 100
    .byte 104
    .byte 108
    .byte 112
    .byte $ff
```

You should see flicker or missing bars.

This demonstrates that the next IRQ must be scheduled far enough ahead.

### 2. Change the spacing

Try setup lines 8 raster lines apart:

```asm
setup_lines:
    .byte 92
    .byte 100
    .byte 108
    .byte 116
    .byte 124
    .byte 132
    .byte $ff
```

Observe whether the result remains stable.

Remember to consider badlines and handler runtime.

### 3. Change the colours

Change the colour table:

```asm
bar_colours:
    .byte $02
    .byte $08
    .byte $0a
    .byte $07
    .byte $0a
    .byte $08
```

This gives a warmer colour ramp.

### 4. Move the whole stack

Add or subtract the same amount from each setup line.

For example:

```asm
setup_lines:
    .byte 120
    .byte 136
    .byte 152
    .byte 168
    .byte 184
    .byte 200
    .byte $ff
```

Check whether the chosen stable lines are still non-badlines.

### 5. Try a badline deliberately

Change one setup line so that:

```text
setup line + 1
```

has:

```text
line & 7 = 3
```

The affected bar should look different.

This reinforces that badlines still matter.

## Common mistakes

### Scheduling the next IRQ too close

If the next setup line is too close, the handler may not finish in time.

The raster beam can pass the target line before `$d012` has been updated.

That causes missed bars or flicker.

### Thinking the table draws all bars at once

The table does not draw all bars in one interrupt.

Each interrupt draws one bar and schedules the next one.

### Forgetting the stable line is setup line plus one

Each setup line is the first IRQ.

The visible stable IRQ happens on the following line.

So when checking badlines, check:

```text
setup line + 1
```

not only the setup line itself.

### Thinking stable means left-aligned

The bars are stable, but they still start too far to the right.

That is a separate timing problem.

Stability and horizontal alignment are not the same thing.

### Treating badline avoidance as the final solution

Avoiding badlines is the right first strategy.

It is not the final strategy for all raster effects.

Later we can build badline-aware routines and eventually compensate for stolen cycles.

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

Lesson 29 should address the limitation we have now seen:

> The bars are stable, but they start too far to the right.

The next goal is horizontal alignment.

We will need to move the colour-on write earlier, likely by preparing the colour before the visible part of the target line.

That means Lesson 29 should focus on:

```text
stable bar timing -> left-edge alignment
```

We are still not rushing to dense demo-style raster bars.

We are solving one machine problem at a time.
