# Lesson 27 - Proper full-width raster bars

## Goal

In this lesson we use the stable raster IRQ foundation from Lesson 26 to create a full-width raster colour pulse.

Lesson 26 changed only the border colour register:

```asm
$d020
```

That gave us a stable timing marker, but not a full-width raster bar.

This lesson changes both:

```asm
$d020 - border colour
$d021 - background colour
```

That lets the colour pulse appear across:

```text
left border -> screen area -> right border
```

This is the first controlled step toward proper raster bars.

## What you will build

You will build a C64 program that:

- installs a stable double raster IRQ
- runs visible colour writes on a non-badline
- changes both border and background colour
- holds the colour briefly
- fine-tunes the pulse width with a fixed-cycle instruction
- restores both colours
- repeats the effect every frame

The visible result is a stable blue raster pulse across the screen.

## What this teaches

This lesson teaches that a full-width raster bar is not just a raster interrupt.

It requires:

- stable IRQ timing
- deliberate placement of colour writes
- understanding the difference between border and background colour
- awareness that sequential hardware writes are visible
- awareness that loop timing is coarse
- awareness that fixed-cycle instructions can fine-tune timing
- awareness that badlines still disturb timing

The key lesson is:

> A stable IRQ removes most interrupt jitter, but it does not remove badline disruption.

## Machine concepts

- VIC-II raster interrupts
- border colour
- background colour
- raster line timing
- badlines
- CPU cycle timing
- VIC-II cycle stealing
- full-width raster colour effects

## Assembly concepts

- double IRQ stabilisation
- stack pointer control with `tsx` and `txs`
- predictable delay using `nop`
- timing delay using `bit $00`
- branch timing as one-cycle correction
- hardware register write order
- cycle-based hold loops
- fixed-cycle fine adjustment

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

The program banks out BASIC and KERNAL ROM with:

```asm
lda #$35
sta $01
```

This keeps I/O visible while allowing the program to write directly to the hardware IRQ vector at `$fffe/$ffff`.

## Why both `$d020` and `$d021` are needed

The C64 does not have one single "screen colour" register for the whole visible line.

The border and the screen area are separate.

```asm
$d020 - border colour
$d021 - background colour
```

If we only change `$d020`, we see colour only in the border.

If we change both `$d020` and `$d021`, we can create a colour pulse that appears across the border and screen area in the default text mode.

That is why Lesson 26 produced small border markers, while Lesson 27 produces a fuller line-like effect.

## The write order matters

The colour writes happen one after the other:

```asm
sta $d020
sta $d021
```

Each `sta absolute` instruction takes 4 cycles.

That means the background colour changes several cycles after the border colour.

On the C64, one CPU cycle corresponds to a visible horizontal movement of roughly 8 pixels.

So a 4-cycle delay is large enough to see.

If the order is reversed:

```asm
sta $d021
sta $d020
```

the visible skew changes direction.

This is not a bug.

It is the machine showing that hardware writes are sequential in time.

## Why the bar length changes

The visible bar is held using a small loop:

```asm
ldx #$08

bar_hold:
    dex
    bne bar_hold
```

This loop does not draw pixels directly.

It burns CPU cycles while the raster beam continues moving across the screen.

Each loop iteration takes time:

```asm
dex              // 2 cycles
bne bar_hold     // 3 cycles while the branch is taken, 2 cycles when it exits
```

With `ldx #$08`, the loop takes:

```text
7 taken loops * 5 cycles = 35
1 final loop * 4 cycles  = 4
total                    = 39 cycles
```

Changing the value in `ldx` changes how long the colour remains active.

For example:

```asm
ldx #$04
```

creates a shorter pulse.

```asm
ldx #$09
```

creates a longer pulse.

But increasing the loop counter is a coarse adjustment, because each extra loop iteration adds 5 cycles.

## Fine-tuning with `nop`

The final version uses the loop for coarse timing and one `nop` for fine timing:

```asm
ldx #$08

bar_hold:
    dex
    bne bar_hold

nop
```

A `nop` takes 2 cycles.

This is a smaller adjustment than increasing the loop count from `#$08` to `#$09`.

That distinction matters.

The lesson is not only that we can hold a colour for longer.

The lesson is that raster timing is tuned in cycles.

## Badline awareness

A badline happens when the VIC-II needs to fetch the next row of character data.

During a badline, the VIC-II steals CPU cycles.

That means cycle-timed code can be delayed or stretched.

With the normal `$d011` value of `$1b`, the YSCROLL value is 3.

That means badlines occur where:

```text
raster line & 7 = 3
```

In this lesson:

```asm
.const setup_line = 92
```

The stable IRQ happens on the following line:

```text
setup_line + 1 = 93
```

And:

```text
93 & 7 = 5
```

So the visible colour writes happen on a non-badline.

That is deliberate.

## What happens if you choose a badline

If you change:

```asm
.const setup_line = 92
```

to:

```asm
.const setup_line = 90
```

then the stable IRQ happens on:

```text
90 + 1 = 91
```

And:

```text
91 & 7 = 3
```

That places the visible colour work on a badline.

The result should look different because the VIC-II steals cycles while the CPU is trying to run the timing code.

This proves an important point:

> Stable IRQ timing and badline-safe timing are not the same thing.

For this lesson, we avoid badlines.

Later lessons can compensate for them deliberately.

## Code walkthrough

### BASIC loader

The program starts with a BASIC loader:

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

It then banks out BASIC and KERNAL ROM while keeping I/O visible:

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

The first IRQ handler is installed:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff
```

The first raster IRQ line is selected:

```asm
lda #setup_line
sta $d012
```

Because the line is below 256, the raster high bit in `$d011` is cleared:

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

The setup IRQ saves the registers:

```asm
pha

txa
pha

tya
pha
```

It installs the second IRQ handler:

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

It saves the current stack pointer in `X`:

```asm
tsx
```

Then it enables interrupts again:

```asm
cli
```

This allows the second IRQ to interrupt the first IRQ.

Finally, it waits using predictable `nop` instructions:

```asm
nop
nop
nop
...
```

Each `nop` takes 2 cycles.

This gives the second IRQ a predictable area to interrupt.

## The stable IRQ

The stable IRQ begins by restoring the stack pointer:

```asm
txs
```

This discards the second IRQ's own return frame.

The second IRQ then becomes the real handler that finishes the original interrupt path.

A small timing delay follows:

```asm
ldx #$08

stable_delay:
    dex
    bne stable_delay
```

Then we use a 3-cycle delay:

```asm
bit $00
```

Here `bit $00` is not used for its logical result.

It is used because zero-page `bit` takes 3 cycles.

Then the code performs a final one-cycle correction:

```asm
lda $d012
cmp $d012

beq stable_point
```

The raster register may change between the two reads.

The branch is either taken or not taken.

A taken branch takes 3 cycles.

A not-taken branch takes 2 cycles.

Since the branch target is the next instruction, both paths continue at the same code, but with a one-cycle timing difference.

## Drawing the full-width pulse

The visible colour pulse starts here:

```asm
stable_point:
    lda #$06
    sta $d020
    sta $d021
```

This sets:

```text
border     = blue
background = blue
```

The pulse is held for a short time:

```asm
ldx #$08

bar_hold:
    dex
    bne bar_hold

nop
```

The `bar_hold` loop gives the coarse pulse width.

The final `nop` adds a 2-cycle fine adjustment so the pulse reaches the right side cleanly without increasing the loop by a full 5 cycles.

Then both colours are restored:

```asm
lda #$00
sta $d020
sta $d021
```

This creates the visible raster pulse.

## Restoring the IRQ for the next frame

The stable IRQ then restores the setup IRQ:

```asm
lda #<irq_setup
sta $fffe

lda #>irq_setup
sta $ffff
```

It restores the original setup line:

```asm
lda #setup_line
sta $d012
```

It clears the raster high bit:

```asm
lda $d011
and #$7f
sta $d011
```

It acknowledges the raster interrupt:

```asm
lda #%00000001
sta $d019
```

Finally, it restores the registers saved by the setup IRQ:

```asm
pla
tay

pla
tax

pla
```

Then it returns:

```asm
rti
```

Because `txs` discarded the second IRQ's return frame, this `rti` returns from the original first interrupt.

## What you should see

You should see a stable blue raster pulse across the screen.

The exact visual shape depends on:

- write order
- hold-loop length
- fine-tuning instructions
- chosen raster line
- whether the line is a badline
- PAL/NTSC timing differences

With the final version, the pulse should be stable and visible across the border and screen area.

## Experiments

### 1. Reverse the write order

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

Do the same for the restore writes.

Observe how the visible skew changes.

This proves that hardware register write order matters.

### 2. Change the hold length

Change:

```asm
ldx #$08
```

to:

```asm
ldx #$04
```

Then try:

```asm
ldx #$06
```

and:

```asm
ldx #$09
```

The bar changes length because the colour is active for a different number of CPU cycles.

### 3. Remove the fine-tuning `nop`

Remove this line after the hold loop:

```asm
nop
```

The pulse should become slightly shorter.

This demonstrates that a single 2-cycle instruction can visibly affect raster timing.

### 4. Add another fine-tuning instruction

Try adding a second `nop`:

```asm
nop
nop
```

Then try replacing both with:

```asm
bit $00
```

A zero-page `bit` takes 3 cycles.

This gives you a different fine-tuning step.

### 5. Move to a badline

Change:

```asm
.const setup_line = 92
```

to:

```asm
.const setup_line = 90
```

The stable IRQ then runs on line 91.

With the normal `$d011 = $1b`, line 91 is a badline because:

```text
91 & 7 = 3
```

The result should look different.

This demonstrates that badlines disturb cycle-timed code even when the IRQ itself is stable.

### 6. Try nearby safe lines

Try setup lines such as:

```asm
.const setup_line = 91
.const setup_line = 92
.const setup_line = 93
```

Remember that the stable IRQ runs on:

```text
setup_line + 1
```

Avoid cases where:

```text
(setup_line + 1) & 7 = 3
```

## Common mistakes

### Thinking stable IRQ means stable raster bar

A stable IRQ solves interrupt entry jitter.

It does not stop the VIC-II from stealing cycles on badlines.

### Forgetting that `$d020` and `$d021` are separate

`$d020` affects the border.

`$d021` affects the screen background in the default text screen.

A full-width effect must account for both.

### Expecting simultaneous colour changes

The CPU writes to one address at a time.

This:

```asm
sta $d020
sta $d021
```

does not happen simultaneously.

The second write happens several cycles later.

That delay is visible.

### Treating the loop count as pixel width

The loop count does not directly mean pixels.

It means CPU time.

The raster beam turns that CPU time into visible horizontal distance.

### Calling a badline result broken

A badline result is not broken.

It is evidence.

It shows that the VIC-II has taken cycles away from the CPU.

For this lesson, we avoid badlines. Later, we can compensate for them deliberately.

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

Lesson 28 can now move from a single full-width pulse to multiple raster bars.

The next step is to make the colour data-driven.

That means using a table of colours and writing several timed colour changes in one stable interrupt.

But we should keep one rule from this lesson:

> First make it work on safe lines. Then make it badline-aware.

We now understand why.
