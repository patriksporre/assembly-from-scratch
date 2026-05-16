# Lesson 30 - Multiple left-aligned raster bars

## Goal

In this lesson we take the left-aligned raster bar from Lesson 29 and apply it to several scheduled bars.

Lesson 29 solved one important problem:

> A stable bar can still start too far to the right.

It solved that by turning the colour on before the target raster line begins.

Lesson 30 adds another problem:

> How do we make several left-aligned bars while still changing their colours from data?

The answer is:

> Keep slow logic out of the raster-critical colour-on path.

This lesson introduces self-modifying code for a precise reason. We patch the colour value before the critical moment, so the actual colour-on path stays as fast as the hard-coded Lesson 29 version.

## What you will build

You will build a C64 program that:

- clears the screen and colour RAM
- installs a stable double raster IRQ
- draws several left-aligned full-width raster bars
- schedules each bar from a setup-line table
- uses a colour table
- patches the immediate operand of `lda #colour`
- keeps the raster-critical colour-on path short and stable
- avoids badlines for now

The visible result is several stable, left-aligned, full-width raster bars.

## What this teaches

This lesson teaches a major raster-programming principle:

> Data-driven code is useful, but logic inside a raster-critical path has visible timing cost.

When we first tried to load the colour from a table directly at the stable point, the bar started too late. The table lookup delayed the colour write.

The solution is to prepare the colour before the beam reaches the critical position.

That is why we use self-modifying code.

The key lesson is:

> Prepare before the critical moment. Execute the shortest possible code at the critical moment.

## Machine concepts

- VIC-II raster interrupts
- double IRQ stabilisation
- full-width raster bars
- left-edge alignment
- PAL raster-line timing
- badline avoidance
- timing-critical code paths

## Assembly concepts

- table-driven scheduling
- table terminator
- indexed lookup
- self-modifying code
- patching an immediate operand
- separating preparation logic from display logic
- preserving the critical timing path

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
| `current_bar` | Current table index |
| `bar_colour_instruction + 1` | Operand byte patched by self-modifying code |

## Why the screen is cleared

The default BASIC screen contains text such as `READY.` and load messages.

Raster bars made by changing `$d021` affect the background colour, but existing character pixels are still drawn on top.

That can make bars look broken.

So this lesson clears screen memory and colour RAM before installing the raster IRQs.

The screen clear writes spaces to `$0400-$07ff`.

The colour clear writes black to `$d800-$dbff`.

## The setup table

The setup lines are:

```asm
setup_lines:
    .byte 92
    .byte 116
    .byte 140
    .byte 164
    .byte 188
    .byte $ff
```

Each setup line creates:

```text
setup IRQ line  = setup line
stable IRQ line = setup line + 1
target bar line = setup line + 2
```

So the target bar lines are:

```text
94, 118, 142, 166, 190
```

The `$ff` value marks the end of the table.

When the scheduler reaches `$ff`, it wraps back to the first entry.

## Badline avoidance

With the normal `$d011` value of `$1b`, YSCROLL is 3.

Badlines occur where:

```text
raster line & 7 = 3
```

The target lines in this lesson are:

```text
94, 118, 142, 166, 190
```

None of those are badlines.

We are avoiding badlines deliberately.

This lesson is not yet about badline compensation.

## The first attempt that failed

The first table-driven colour version used this inside the critical path:

```asm
stable_point:
    ldx current_bar
    lda bar_colours,x

    sta $d020
    sta $d021
```

That is logically correct.

But it is too slow at the critical moment.

The timing cost before the colour write is:

```text
ldx current_bar       4 cycles
lda bar_colours,x     4 cycles
```

That delays the visible colour-on write by 8 cycles.

On a C64, 8 cycles is a large horizontal distance.

The bars started too far to the right.

## Why self-modifying code fixes it

The hard-coded Lesson 29 colour path was:

```asm
lda #$06
sta $d020
sta $d021
```

That is fast:

```text
lda #$06     2 cycles
sta $d020    4 cycles
sta $d021    4 cycles
```

We want to keep that timing, but still change the colour per bar.

So Lesson 30 uses this:

```asm
bar_colour_instruction:
    lda #$06
    sta $d020
    sta $d021
```

The instruction `lda #$06` is stored in memory as two bytes:

```text
A9 06
```

- `$a9` is the opcode for `lda immediate`
- `$06` is the operand - the value loaded into A

The label points to the instruction:

```asm
bar_colour_instruction:
    lda #$06
```

So:

```asm
bar_colour_instruction + 0
```

is the opcode byte.

And:

```asm
bar_colour_instruction + 1
```

is the operand byte.

This code patches only the operand:

```asm
lda bar_colours,x
sta bar_colour_instruction + 1
```

So if the table value is `$03`, the instruction effectively changes from:

```asm
lda #$06
```

to:

```asm
lda #$03
```

The opcode stays the same.

Only the colour value changes.

## Why we do not patch `+0`

We could technically write to:

```asm
bar_colour_instruction
```

That would modify the opcode byte.

But we do not want to change the instruction itself.

We only want to change the value used by the instruction.

Patching the opcode is possible, but dangerous unless the new opcode and following bytes are planned exactly.

For this lesson, we keep the instruction shape fixed:

```asm
lda #colour
```

and patch only the colour byte.

That keeps the cycle timing identical for every colour.

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

The border and background are set to black:

```asm
lda #$00
sta $d020
sta $d021
```

Then the screen and colour RAM are cleared.

The bar index is reset:

```asm
lda #$00
sta current_bar
```

The first colour is patched into the immediate operand:

```asm
ldx current_bar
lda bar_colours,x
sta bar_colour_instruction + 1
```

This ensures the first bar uses the first table colour.

### Interrupt setup

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

The first setup line is loaded from the table:

```asm
ldx current_bar
lda setup_lines,x
sta $d012
```

The raster high bit is cleared:

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

The main program loops forever while the IRQ handlers do the visible work.

## The setup IRQ

The setup IRQ fires on the current setup line.

It saves A, X, and Y:

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

It acknowledges the first raster interrupt:

```asm
lda #%00000001
sta $d019
```

It saves the current stack pointer in X:

```asm
tsx
```

Then it enables interrupts again:

```asm
cli
```

The second IRQ interrupts the first IRQ while it is waiting in predictable `nop` instructions.

## The stable IRQ

The stable IRQ starts by restoring the stack pointer:

```asm
txs
```

This discards the second IRQ return frame.

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

The branch either takes 3 cycles or 2 cycles.

Since the branch target is the next instruction, both paths continue at the same place, but with a one-cycle timing difference.

## The critical colour-on path

At the stable point, the bar colour is loaded with the patched immediate instruction:

```asm
bar_colour_instruction:
    lda #$06
    sta $d020
    sta $d021
```

This is the raster-critical path.

It must stay short.

The colour value may no longer be `$06` when the program runs. The scheduling code patches that operand before each bar.

## Holding and turning off the bar

The colour is held to the right-side position:

```asm
ldx #$08

bar_hold:
    dex
    bne bar_hold

nop
```

Then the colour remains active for one full PAL raster line:

```asm
ldx #$0c

one_line_delay:
    dex
    bne one_line_delay

nop
```

This delay takes 63 cycles on a PAL C64.

Then the colours are restored to black:

```asm
lda #$00
sta $d020
sta $d021
```

## Scheduling the next bar

The scheduler advances the table index:

```asm
ldx current_bar
inx
```

It checks for the table terminator:

```asm
lda setup_lines,x
cmp #$ff
bne store_next_bar
```

If it reaches `$ff`, it wraps to the first bar:

```asm
ldx #$00
lda setup_lines,x
```

The next index is stored:

```asm
stx current_bar
```

Then the next colour is patched into the immediate operand:

```asm
lda bar_colours,x
sta bar_colour_instruction + 1
```

This is the self-modifying part.

It happens after the current bar has been drawn, away from the colour-on critical path.

Then the setup IRQ and next setup line are installed:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff

lda setup_lines,x
sta $d012
```

The interrupt is acknowledged, registers are restored, and the handler returns with `rti`.

## What you should see

You should see several stable, left-aligned, full-width raster bars.

The bars should have different colours according to the colour table.

They should not start too far to the right.

They should not flicker.

The success criteria are:

- multiple bars are visible
- bars are left-aligned
- bars are stable
- colours come from a table
- the critical path stays short
- the result avoids badlines

## Experiments

### 1. Break the critical path deliberately

Replace:

```asm
bar_colour_instruction:
    lda #$06
```

with:

```asm
ldx current_bar
lda bar_colours,x
```

The bars should shift horizontally because the colour-on write is delayed.

This proves why self-modifying code was introduced.

### 2. Change the colour table

Try:

```asm
bar_colours:
    .byte $02
    .byte $08
    .byte $0a
    .byte $07
    .byte $0a
```

This creates a warmer colour ramp.

### 3. Change the spacing

Try moving the setup lines closer together.

For example:

```asm
setup_lines:
    .byte 92
    .byte 108
    .byte 124
    .byte 140
    .byte 156
    .byte $ff
```

If the spacing becomes too tight, bars may flicker or disappear.

### 4. Patch the opcode carefully

For understanding only, inspect what would happen if you patched:

```asm
bar_colour_instruction
```

instead of:

```asm
bar_colour_instruction + 1
```

That would modify the opcode, not the colour value.

Do not keep that in the final program.

### 5. Move the stack

Move all setup lines down by the same amount.

Remember:

```text
target line = setup line + 2
```

Avoid badlines for now.

## Common mistakes

### Thinking self-modifying code is magic

It is not magic.

Code is bytes in RAM.

The CPU reads those bytes as instructions.

If we write to the byte that holds an instruction operand, the next execution uses the new value.

### Patching the wrong byte

For:

```asm
lda #$06
```

the opcode is at `+0`.

The operand is at `+1`.

We patch `+1`.

### Putting table lookup back into the critical path

This will work logically, but it will move the visible bar.

The critical path must remain short.

### Forgetting that this is PAL-timed

The one-line delay assumes:

```text
PAL C64 raster line = 63 CPU cycles
```

This exact delay is not correct for NTSC machines.

### Thinking this solves badlines

This lesson avoids badlines.

It does not compensate for them.

Badline support comes later.

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

Lesson 31 should measure the runtime budget of the raster handler.

The next question is:

> How close can we place the bars before the next IRQ is scheduled too late?

That will prepare us for tighter bars, badline-aware scheduling, animation, and sine movement.

The destination is still:

```text
stable
left-aligned
full-width
multi-bar
badline-aware
data-driven
animated
sine-controlled
demo-ready
```
