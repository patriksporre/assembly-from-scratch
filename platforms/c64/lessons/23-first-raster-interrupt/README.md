# Lesson 23 - First raster interrupt

## Goal

Set up the first VIC-II raster interrupt.

Lesson 22 introduced interrupts using CIA #1 Timer A.

This lesson uses the same interrupt mechanism, but changes the interrupt source.

Instead of a CIA timer causing the interrupt, the VIC-II causes the interrupt when the raster reaches a chosen line.

The main program does almost nothing:

```asm
main_loop:
    jmp main_loop
```

The border changes because the VIC-II interrupts the CPU once per frame.

## What you will build

You will build a C64 program where the VIC-II requests an IRQ at raster line 100.

When the raster reaches that line:

```text
VIC-II requests an IRQ
CPU jumps through $fffe/$ffff
irq_handler runs
border colour changes
VIC-II interrupt is acknowledged
handler returns with rti
main loop continues
```

The visible result is a flashing border with a horizontal boundary around raster line 100.

That boundary shows where the interrupt happened.

## What this teaches

This lesson teaches:

- how to use the VIC-II as an interrupt source
- how a raster interrupt differs from a timer interrupt
- how to choose a raster line with `$d012`
- how to use bit 7 of `$d011` as the high raster bit
- how to enable VIC-II raster interrupts with `$d01a`
- how to acknowledge VIC-II interrupts with `$d019`
- how the IRQ vector at `$fffe/$ffff` is reused
- why the interrupt handler still preserves A, X, and Y
- why interrupt handlers return with `rti`
- why a colour change creates a visible line at the interrupt position

The key structure is:

```text
raster reaches chosen line -> VIC-II requests IRQ -> handler changes border
```

## Important scope note

This is the first raster interrupt lesson.

It is not yet a proper raster bar.

It does not chain interrupts.

It does not set one colour at one line and another colour at a second line.

It only proves that the VIC-II can call our code at a chosen raster line.

The next lesson will build on this with chained raster interrupts.

## From timer interrupt to raster interrupt

Lesson 22 used CIA #1 Timer A.

The important timer registers were:

```text
$dc04 - CIA #1 Timer A low byte
$dc05 - CIA #1 Timer A high byte
$dc0d - CIA #1 interrupt control/status
$dc0e - CIA #1 Timer A control
```

This lesson uses the VIC-II instead.

The important raster interrupt registers are:

```text
$d011 - VIC-II control register 1, includes high raster bit
$d012 - raster line low byte
$d019 - VIC-II interrupt status/acknowledge
$d01a - VIC-II interrupt enable
```

The general interrupt mechanism is the same:

```text
hardware source requests IRQ
CPU jumps through $fffe/$ffff
handler runs
source is acknowledged
handler returns with rti
```

Only the hardware source changes.

## Files

This lesson contains:

```text
platforms/c64/lessons/23-first-raster-interrupt/
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
// Lesson 23: First raster interrupt
//
// This lesson introduces the first VIC-II raster interrupt.
//
// Lesson 22 used CIA #1 Timer A as the interrupt source.
//
// This lesson uses the VIC-II raster interrupt instead.
//
// The main program does almost nothing.
// It sits in an infinite loop.
//
// When the raster reaches line 100,
// the VIC-II requests an IRQ.
//
// The CPU then interrupts the main loop,
// jumps to irq_handler,
// changes the border colour,
// acknowledges the VIC-II interrupt,
// restores the CPU registers,
// and returns with rti.
//
// This is the foundation for proper C64 raster effects.

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
    sei                       // Disable IRQs while we change interrupt setup

    lda #$35                  // Keep I/O visible, but bank out BASIC and KERNAL ROM
    sta $01                   // This lets us write the hardware IRQ vector at $fffe/$ffff

    lda #$00                  // Load colour 0, black
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    lda #%01111111            // Disable all CIA #1 interrupt sources
    sta $dc0d                 // Write interrupt mask to CIA #1 interrupt control register

    lda #%01111111            // Disable all CIA #2 interrupt sources
    sta $dd0d                 // Write interrupt mask to CIA #2 interrupt control register

    lda $dc0d                 // Acknowledge any pending CIA #1 interrupt
    lda $dd0d                 // Acknowledge any pending CIA #2 interrupt

    lda #<irq_handler         // Load low byte of our IRQ handler address
    sta $fffe                 // Store low byte in the hardware IRQ vector

    lda #>irq_handler         // Load high byte of our IRQ handler address
    sta $ffff                 // Store high byte in the hardware IRQ vector

    lda #100                  // Raster line where the interrupt should happen
    sta $d012                 // Store low 8 bits of the raster line

    lda $d011                 // Load VIC-II control register 1
    and #$7f                  // Clear bit 7 because raster line 100 is below 256
    sta $d011                 // Store updated VIC-II control register 1

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Clear any pending VIC-II raster interrupt

    lda #%00000001            // Bit 0 enables VIC-II raster interrupts
    sta $d01a                 // Enable raster interrupt source

    cli                       // Enable IRQs again

main_loop:
    jmp main_loop             // Do nothing. The raster interrupt runs independently

// -----------------------------------------------------------------------------
// IRQ handler
// -----------------------------------------------------------------------------
//
// This routine runs automatically when the VIC-II raster reaches line 100.
//
// The main program does not call this routine.
// The VIC-II requests an interrupt,
// and the CPU jumps here through the IRQ vector at $fffe/$ffff.
//
// Input:
//
//   none
//
// Output:
//
//   border colour changed
//   VIC-II raster interrupt acknowledged
//
// Destroys:
//
//   none, after restoration
//
// Preserves:
//
//   A
//   X
//   Y
//   flags are restored by rti
//
// Memory used:
//
//   stack page $0100-$01ff

irq_handler:
    pha                       // Save A on the stack

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    inc $d020                 // Change border colour once per raster interrupt

    lda #%00000001            // Bit 0 acknowledges a VIC-II raster interrupt
    sta $d019                 // Acknowledge the VIC-II raster interrupt

    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt
```

## Code walkthrough

### BASIC loader

The BASIC loader creates:

```basic
10 SYS 2061
```

When you type `RUN`, BASIC starts the machine code at `$080d`.

### Disabling IRQs during setup

The program starts with:

```asm
sei
```

This disables IRQ handling while the interrupt setup is changed.

We do not want an interrupt to occur while the IRQ vector or interrupt registers are only partly configured.

### Banking out BASIC and KERNAL ROM

The program writes:

```asm
lda #$35
sta $01
```

`$01` controls the C64 memory configuration.

The value `$35` keeps I/O visible but banks out BASIC and KERNAL ROM.

This lets us write the hardware IRQ vector in RAM at:

```text
$fffe/$ffff
```

This is not BASIC-friendly. Reset the emulator to stop the program.

### Disabling CIA interrupts

The program disables CIA interrupt sources:

```asm
lda #%01111111
sta $dc0d

lda #%01111111
sta $dd0d
```

This keeps the CIA timers from interrupting us.

Lesson 23 is about the VIC-II raster interrupt only.

### Acknowledging pending CIA interrupts

The program reads:

```asm
lda $dc0d
lda $dd0d
```

Reading the CIA interrupt control/status registers acknowledges pending CIA interrupt flags.

This clears old interrupt requests before the VIC-II raster interrupt is enabled.

### Installing the IRQ handler

The hardware IRQ vector is:

```text
$fffe - low byte
$ffff - high byte
```

The code stores the address of `irq_handler` there:

```asm
lda #<irq_handler
sta $fffe

lda #>irq_handler
sta $ffff
```

From this point, when an IRQ occurs, the CPU jumps to `irq_handler`.

### Choosing the raster line

This chooses raster line 100:

```asm
lda #100
sta $d012
```

`$d012` contains the low 8 bits of the current raster line and also the low 8 bits of the raster interrupt target.

Because line 100 is below 256, the high raster bit must be clear:

```asm
lda $d011
and #$7f
sta $d011
```

Bit 7 of `$d011` is the high raster bit.

For raster lines 0-255, it should be 0.

For raster lines 256 and above, it should be 1.

### Acknowledging pending VIC-II interrupts

Before enabling the raster interrupt, the program clears any pending VIC-II raster interrupt:

```asm
lda #%00000001
sta $d019
```

`$d019` is the VIC-II interrupt status/acknowledge register.

For the VIC-II, writing a 1 to the relevant bit acknowledges that interrupt source.

Bit 0 is the raster interrupt bit.

### Enabling VIC-II raster interrupts

This enables the raster interrupt source:

```asm
lda #%00000001
sta $d01a
```

`$d01a` is the VIC-II interrupt enable register.

Bit 0 enables raster interrupts.

### Enabling CPU IRQ handling

The setup ends with:

```asm
cli
```

This clears the interrupt disable flag.

Now the CPU can respond to IRQs.

At this point:

```text
the IRQ vector points to irq_handler
CIA interrupts are disabled
VIC-II raster interrupt is enabled
the raster target is line 100
CPU IRQ handling is enabled
```

So the interrupt can happen.

### Main loop

The main program does nothing:

```asm
main_loop:
    jmp main_loop
```

The border colour changes because the raster interrupt handler runs independently.

### IRQ handler

The handler first saves A, X, and Y:

```asm
pha
txa
pha
tya
pha
```

Then it changes the border colour:

```asm
inc $d020
```

Then it acknowledges the VIC-II raster interrupt:

```asm
lda #%00000001
sta $d019
```

Finally, it restores Y, X, and A:

```asm
pla
tay
pla
tax
pla
```

and returns with:

```asm
rti
```

## The visible result

You should see the whole border changing colour.

You should also see a horizontal boundary around raster line 100.

This is expected.

The interrupt happens at line 100, so the border colour changes while the frame is already being drawn.

That means:

```text
above line 100 - previous border colour
below line 100 - new border colour
```

Because the interrupt happens every frame and `inc $d020` changes the colour each time, the whole border appears to flash.

The boundary line proves that the colour change is happening at the chosen raster position.

## The key idea

Earlier raster lessons used polling:

```text
main program waits for raster line
main program changes colour
```

This lesson uses a raster interrupt:

```text
VIC-II reaches raster line
VIC-II interrupts CPU
IRQ handler changes colour
main loop continues
```

That is a major shift.

The display hardware is now calling our code at a chosen screen position.

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/23-first-raster-interrupt
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

You should see the border colour changing, with a visible boundary around raster line 100.

## Machine concepts

This lesson introduces:

- VIC-II raster interrupts
- raster interrupt target line through `$d012`
- high raster bit in `$d011`
- VIC-II interrupt acknowledge through `$d019`
- VIC-II interrupt enable through `$d01a`
- the raster interrupt as a screen-position event

It reuses:

- BASIC loader at `$0801`
- machine code start at `$080d`
- C64 memory configuration through `$01`
- hardware IRQ vector at `$fffe/$ffff`
- disabling CIA interrupts through `$dc0d` and `$dd0d`
- `sei`
- `cli`
- `rti`
- register preservation in an IRQ handler
- stack page `$0100-$01ff`

## Assembly concepts

This lesson introduces or reinforces:

- setting a hardware interrupt source
- using bit masks for hardware control registers
- using `<` and `>` to install a handler address
- preserving A, X, and Y inside an interrupt handler
- acknowledging the active interrupt source
- returning from interrupt with `rti`

It reuses:

- `lda`
- `sta`
- `inc`
- `and`
- `pha`
- `pla`
- `txa`
- `tax`
- `tya`
- `tay`
- `jmp`
- `.word`
- `.byte`
- `.text`

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0001` | C64 processor port, memory configuration |
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$0100-$01ff` | Stack page used by CPU and handler saves |
| `$d011` | VIC-II control register 1, includes high raster bit |
| `$d012` | VIC-II raster line low byte and raster interrupt target |
| `$d019` | VIC-II interrupt status/acknowledge register |
| `$d01a` | VIC-II interrupt enable register |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |
| `$dc0d` | CIA #1 interrupt control/status register |
| `$dd0d` | CIA #2 interrupt control/status register |
| `$fffe` | Hardware IRQ vector low byte |
| `$ffff` | Hardware IRQ vector high byte |

## Experiments

### Move the interrupt line

Change:

```asm
lda #100
sta $d012
```

to:

```asm
lda #50
sta $d012
```

Build and run again.

The visible boundary should move upward.

Try:

```asm
lda #180
sta $d012
```

The boundary should move downward.

### Change what the interrupt does

Replace:

```asm
inc $d020
```

with:

```asm
lda #$02
sta $d020
```

Now the interrupt sets a fixed border colour instead of incrementing it.

### Change the background instead

Add:

```asm
inc $d021
```

inside the IRQ handler.

The background colour should also change once per raster interrupt.

### Forget to acknowledge the VIC-II interrupt

Temporarily remove:

```asm
lda #%00000001
sta $d019
```

The program may behave incorrectly because the interrupt request remains pending.

Put the acknowledgement back afterwards.

### Forget to preserve registers

Temporarily remove the save and restore of X or Y.

This program may still appear to work because the main loop does not use X or Y.

Later programs will depend on correct preservation.

Put the preservation back afterwards.

## Common mistakes

### Expecting a clean raster bar

This lesson does not create a raster bar yet.

It creates one interrupt at one raster line.

A raster bar needs at least two colour changes, which comes next.

### Forgetting that `$d019` is acknowledged by writing 1

For the VIC-II, writing 1 to the relevant interrupt bit acknowledges it.

This differs from the CIA, where reading the interrupt register acknowledges it.

### Confusing `$d019` and `$d01a`

`$d019` is interrupt status and acknowledge.

`$d01a` is interrupt enable.

Both matter.

### Forgetting the high raster bit

`$d012` is only the low 8 bits.

Bit 7 of `$d011` is needed for raster lines 256 and above.

This lesson uses line 100, so the high bit is cleared.

### Using `rts` instead of `rti`

Interrupt handlers must return with `rti`.

`rts` is for normal subroutines.

## What comes next

Next lesson:

```text
24 - Chained raster interrupts
```

Lesson 23 proved that the VIC-II can interrupt the CPU at one raster line.

Lesson 24 will set up a second raster interrupt from inside the first handler.

That gives us:

```text
line 100 - set border colour
line 120 - set border colour back
```

This is the first interrupt-driven raster band and the foundation for proper raster bars.
