# Lesson 22 - Interrupt basics

## Goal

Introduce a real interrupt on the Commodore 64.

This lesson does not use raster interrupts yet.

Instead, it uses CIA #1 Timer A.

The purpose is to understand the interrupt mechanism itself before we connect it to the raster beam.

The main program does almost nothing:

```asm
main_loop:
    jmp main_loop
```

The border colour changes because a hardware timer interrupts the CPU and runs our interrupt handler.

## What you will build

You will build a C64 program where CIA #1 Timer A counts down in the background.

When the timer reaches zero, it requests an IRQ.

The CPU then:

```text
finishes the current instruction
saves its current position and status on the stack
jumps to the IRQ handler
runs the handler
returns with rti
continues where it was interrupted
```

The interrupt handler counts timer interrupts in software.

The visible border colour changes roughly every two seconds.

## What this teaches

This lesson teaches:

- what an interrupt is
- the difference between normal flow, subroutine flow, and interrupt flow
- how a hardware source can interrupt the CPU
- how to install an IRQ handler
- how to enable and acknowledge a CIA timer interrupt
- why interrupt handlers use `rti`, not `rts`
- what the CPU saves automatically
- what the handler must preserve manually
- why `sei` and `cli` matter
- how a fast interrupt can drive a slower visible behaviour
- how interrupt handlers can read and write normal memory
- why shared state between main code and interrupts must be handled carefully

The key structure is:

```text
hardware timer -> IRQ request -> IRQ vector -> handler -> acknowledge -> rti
```

## Important scope note

This is the first real interrupt lesson.

It deliberately does not use:

```text
raster interrupts
$d012
$d019
$d01a
VIC-II interrupt setup
```

Those come next.

This lesson isolates the basic interrupt mechanism using CIA #1 Timer A.

## Normal flow, subroutine flow, and interrupt flow

Normal program flow runs in the order written:

```asm
lda #$00
sta $d020
jmp main_loop
```

A subroutine is called deliberately by the program:

```asm
jsr delay
```

and returns with:

```asm
rts
```

An interrupt is different.

The program does not call the interrupt handler.

Hardware triggers it.

In this lesson, CIA #1 Timer A reaches zero and requests an interrupt.

The CPU then jumps to the interrupt handler automatically.

The handler returns with:

```asm
rti
```

## IRQ, NMI, RESET, and BRK

The 6510/6502 has several interrupt-like mechanisms.

For now, the important ones are:

| Mechanism | Meaning |
|---|---|
| `IRQ` | Maskable interrupt |
| `NMI` | Non-maskable interrupt |
| `RESET` | CPU reset vector |
| `BRK` | Software interrupt instruction |

This lesson uses `IRQ`.

IRQ is called maskable because it can be disabled with:

```asm
sei
```

and enabled with:

```asm
cli
```

`NMI` is different because it is non-maskable. `sei` does not block NMI.

We leave NMI alone for now.

## Interrupt sources on the C64

The CPU has one IRQ vector, but several hardware chips can request an IRQ.

Common sources include:

```text
CIA #1 Timer A
CIA #1 Timer B
VIC-II raster interrupt
VIC-II sprite collision interrupt
VIC-II light pen interrupt
```

The CPU does not automatically know what caused the interrupt.

A real IRQ handler may need to inspect the relevant status registers and decide what to handle.

This lesson uses one source only:

```text
CIA #1 Timer A
```

The next lesson will use:

```text
VIC-II raster interrupt
```

## One IRQ vector, many possible sources

The CPU uses one IRQ entry point:

```text
$fffe - low byte of handler address
$ffff - high byte of handler address
```

When an IRQ occurs, the CPU reads this address and jumps there.

That means there can be many interrupt sources, but the CPU enters through one IRQ vector.

A program can then choose how to organise handlers.

Later raster lessons will also change the IRQ vector from inside an interrupt handler to create chained raster interrupts.

## What the CPU saves automatically

When an IRQ occurs, the CPU automatically saves:

```text
program counter
processor status register
```

That means it remembers where it was and what the flags were.

The CPU does not automatically save:

```text
A
X
Y
```

So if the interrupt handler uses A, X, or Y, it must preserve them manually.

That is why the handler saves them on the stack.

## Why `rti` is not `rts`

A normal subroutine returns with:

```asm
rts
```

An interrupt handler returns with:

```asm
rti
```

`rti` means return from interrupt.

It restores the processor status and program counter that the CPU saved when the interrupt happened.

Using `rts` from an interrupt handler would be wrong.

## Why the handler saves A, X, and Y

An interrupt can happen between almost any two instructions in the main program.

The main program may be using A, X, or Y when the interrupt occurs.

So the handler saves them:

```asm
pha

txa
pha

tya
pha
```

and restores them before returning:

```asm
pla
tay

pla
tax

pla
```

This keeps the interrupted program safe.

## Shared memory and interrupt handlers

Interrupt handlers run on the same CPU and use the same memory as the main program.

That means an interrupt handler can read and write:

```text
normal variables
screen memory
colour RAM
zero page
hardware registers
tables
state bytes
```

In this lesson, the interrupt handler uses:

```asm
dec irq_counter
```

`irq_counter` is just a normal byte in memory.

The interrupt handler can access it exactly like the main program can.

This is powerful, but it must be handled carefully.

If both the main program and the interrupt handler modify the same memory, they can interfere with each other.

For example, one part of the program may read a value, then an interrupt changes it, then the main program resumes and writes an old value back.

That is called a race condition.

A common safe pattern is:

```text
interrupt sets a simple flag or counter
main loop does the larger work
```

We will use that pattern later.

## Hardware interrupt frequency and visible behaviour frequency

CIA Timer A fires regularly.

But the visible border colour does not need to change every time.

This lesson separates two ideas:

```text
hardware interrupt frequency
visible behaviour frequency
```

Timer A uses the largest 16-bit timer value:

```text
$ffff = 65535
```

On a PAL C64, the CPU runs at roughly:

```text
985,000 cycles per second
```

So the longest Timer A period is approximately:

```text
65536 / 985000 = 0.0665 seconds
```

That is about 15 interrupts per second.

To change the border roughly every two seconds, we count about 30 timer interrupts:

```text
0.0665 seconds * 30 = 1.995 seconds
```

So the interrupt still fires regularly, but the visible work happens only when `irq_counter` reaches zero.

## Files

This lesson contains:

```text
platforms/c64/lessons/22-interrupt-basics/
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
// Lesson 22: Interrupt basics
//
// This lesson introduces a real interrupt.
//
// We do not use raster interrupts yet.
// Instead, we use CIA #1 Timer A.
//
// The main program does almost nothing.
// It sits in an infinite loop.
//
// CIA #1 Timer A counts down in the background.
// When the timer reaches zero, it requests an interrupt.
//
// The CPU then interrupts the main loop,
// jumps to irq_handler,
// acknowledges the interrupt,
// updates a software counter,
// sometimes changes the border colour,
// restores the CPU registers,
// and returns with rti.
//
// This is our first real interrupt-driven program.
//
// Timer A is a 16-bit timer.
// The largest value it can count down from is:
//
//   $ffff = 65535
//
// On a PAL C64, the CPU runs at roughly 985,000 cycles per second.
//
// So the longest Timer A period is approximately:
//
//   65536 / 985000 = 0.0665 seconds
//
// That is about 15 interrupts per second.
//
// To make the visible border colour change roughly every two seconds,
// we count about 30 timer interrupts:
//
//   0.0665 seconds * 30 = 1.995 seconds
//
// So the interrupt still fires regularly,
// but the visible work only happens when irq_counter reaches zero.

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

    lda #$ff                  // Timer A low byte
    sta $dc04                 // Store low byte in CIA #1 Timer A latch

    lda #$ff                  // Timer A high byte
    sta $dc05                 // Store high byte in CIA #1 Timer A latch

    lda #30                   // Count about 30 timer interrupts
    sta irq_counter           // This gives roughly two seconds between visible updates

    lda #%10000001            // Enable CIA #1 Timer A interrupt
    sta $dc0d                 // Bit 7 = set mask, bit 0 = Timer A interrupt

    lda #%00010001            // Start Timer A and force-load the latch
    sta $dc0e                 // CIA #1 Timer A control register

    cli                       // Enable IRQs again

main_loop:
    jmp main_loop             // Do nothing. The interrupt runs independently

// -----------------------------------------------------------------------------
// IRQ handler
// -----------------------------------------------------------------------------
//
// This routine runs automatically when CIA #1 Timer A reaches zero.
//
// The main program does not call this routine.
// The hardware interrupt system calls it.
//
// The timer interrupt fires much more often than the visible border update.
// Timer A with value $ffff fires roughly every 0.0665 seconds on a PAL C64.
// We count about 30 interrupts to get roughly two seconds:
//
//   0.0665 seconds * 30 = 1.995 seconds
//
// Input:
//
//   none
//
// Output:
//
//   irq_counter decremented
//   border colour changed when irq_counter reaches zero
//   CIA #1 Timer A interrupt acknowledged
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
//   irq_counter

irq_handler:
    pha                       // Save A on the stack

    txa                       // Copy X into A
    pha                       // Save X on the stack

    tya                       // Copy Y into A
    pha                       // Save Y on the stack

    lda $dc0d                 // Acknowledge CIA #1 interrupt by reading interrupt register

    dec irq_counter           // Count down one timer interrupt
    bne irq_done              // If the counter is not zero, skip the visible work

    lda #30                   // Reload the software counter for roughly two seconds
    sta irq_counter           // Store it for the next interval

    inc $d020                 // Change the border colour roughly every two seconds

irq_done:
    pla                       // Restore saved Y into A
    tay                       // Put it back into Y

    pla                       // Restore saved X into A
    tax                       // Put it back into X

    pla                       // Restore saved A

    rti                       // Return from interrupt

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

irq_counter:
    .byte 30                  // Counts timer interrupts before the visible update
```

## Code walkthrough

### BASIC loader

The BASIC loader creates:

```basic
10 SYS 2061
```

When you type `RUN`, BASIC starts the machine code at `$080d`.

### Disabling IRQs during setup

The first instruction is:

```asm
sei
```

This disables normal IRQ handling while we change the interrupt setup.

That matters because we do not want an interrupt to occur while the IRQ vector or hardware registers are only half configured.

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

### Disabling CIA interrupt sources

The program first disables CIA interrupt sources:

```asm
lda #%01111111
sta $dc0d

lda #%01111111
sta $dd0d
```

For CIA interrupt mask writes:

```text
bit 7 = 0 means clear selected mask bits
bit 7 = 1 means set selected mask bits
```

So `%01111111` clears all selected interrupt enable bits.

This reduces surprises from old or unwanted interrupt sources.

### Acknowledging pending CIA interrupts

The program then reads:

```asm
lda $dc0d
lda $dd0d
```

Reading the CIA interrupt control/status register acknowledges pending CIA interrupt flags.

This clears old interrupt requests before starting our own timer.

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

From this point, when an IRQ occurs, the CPU will jump to `irq_handler`.

### Setting Timer A

CIA #1 Timer A is a 16-bit down-counter.

Its latch is loaded through:

```text
$dc04 - low byte
$dc05 - high byte
```

The code loads the largest possible value:

```asm
lda #$ff
sta $dc04

lda #$ff
sta $dc05
```

This gives the longest basic timer period available from one Timer A countdown.

### Initialising the software counter

The timer interrupt fires roughly 15 times per second.

We want a visible border change roughly every two seconds.

So we set:

```asm
lda #30
sta irq_counter
```

The interrupt handler decrements this counter each time Timer A fires.

Only when it reaches zero does the handler change the border colour.

### Enabling CIA Timer A interrupts

This enables Timer A as an interrupt source:

```asm
lda #%10000001
sta $dc0d
```

Bit 7 is set, meaning set selected mask bits.

Bit 0 is set, meaning Timer A interrupt.

Together this enables CIA #1 Timer A interrupt.

### Starting Timer A

This starts Timer A:

```asm
lda #%00010001
sta $dc0e
```

The important bits are:

```text
bit 0 = start timer
bit 4 = force-load latch into timer
```

So this loads the timer from `$dc04/$dc05` and starts counting.

### Enabling CPU IRQ handling

The setup ends with:

```asm
cli
```

This clears the interrupt disable flag.

Now the CPU can respond to IRQs.

### Main loop

The main program does nothing:

```asm
main_loop:
    jmp main_loop
```

The border colour changes because the interrupt handler runs independently.

### IRQ handler

The handler first saves A, X, and Y.

Then it acknowledges the CIA interrupt:

```asm
lda $dc0d
```

Then it decrements the software counter:

```asm
dec irq_counter
bne irq_done
```

If the counter is not zero, it skips the visible work.

If the counter reaches zero, the handler reloads it and changes the border:

```asm
lda #30
sta irq_counter

inc $d020
```

Finally, it restores Y, X, and A, then returns with:

```asm
rti
```

## The key idea

Lesson 22 introduces interrupt-driven programming.

The main loop is no longer responsible for the visible behaviour.

The visible behaviour is driven by a hardware timer.

This is a major shift:

```text
program decides when to call code
```

becomes:

```text
hardware decides when code runs
```

## How to build and run

From this lesson folder:

```bash
cd platforms/c64/lessons/22-interrupt-basics
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

The border colour should change roughly every two seconds.

## Machine concepts

This lesson introduces:

- real IRQ interrupts
- CIA #1 Timer A
- IRQ vector at `$fffe/$ffff`
- CIA interrupt enable and acknowledge through `$dc0d`
- Timer A latch at `$dc04/$dc05`
- Timer A control at `$dc0e`
- interrupt-driven execution
- software counter inside an interrupt handler
- shared memory between interrupt handler and program

It also prepares for:

- VIC-II raster interrupts
- chained interrupt handlers
- interrupt-driven raster effects

## Assembly concepts

This lesson introduces or reinforces:

- `sei`
- `cli`
- `rti`
- `pha`
- `pla`
- `txa`
- `tax`
- `tya`
- `tay`
- `dec`
- preserving A, X, and Y
- software counters
- interrupt-safe routine structure

It reuses:

- `lda`
- `sta`
- `inc`
- `bne`
- `jmp`
- `.word`
- `.byte`
- `.text`
- `<` for low byte
- `>` for high byte

## Memory addresses used

| Address | Purpose |
|---|---|
| `$0001` | C64 processor port, memory configuration |
| `$0801` | Start of the BASIC loader |
| `$080d` | Start of the machine-code program |
| `$0100-$01ff` | Stack page used by CPU and handler saves |
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |
| `$dc04` | CIA #1 Timer A low byte |
| `$dc05` | CIA #1 Timer A high byte |
| `$dc0d` | CIA #1 interrupt control/status register |
| `$dc0e` | CIA #1 Timer A control register |
| `$dd0d` | CIA #2 interrupt control/status register |
| `$fffe` | Hardware IRQ vector low byte |
| `$ffff` | Hardware IRQ vector high byte |

## Experiments

### Change how often the border changes

Change:

```asm
lda #30
sta irq_counter
```

Try:

```asm
lda #15
sta irq_counter
```

The border should change roughly once per second.

Try:

```asm
lda #60
sta irq_counter
```

The border should change roughly every four seconds.

Remember to change both the initial value and the reload value inside the handler.

### Change the timer period

Change the Timer A latch:

```asm
lda #$ff
sta $dc04

lda #$ff
sta $dc05
```

A smaller timer value causes more frequent interrupts.

Be careful. Very frequent interrupts can make the system spend too much time in the handler.

### Remove the software counter

Move:

```asm
inc $d020
```

so it runs on every interrupt.

The border should change much faster.

Put the counter back afterwards.

### Break register preservation

Temporarily remove the save and restore of X or Y.

This program may still appear to work because the main loop does not use X or Y.

But later programs will depend on correct preservation.

Put the preservation back afterwards.

## Common mistakes

### Using `rts` instead of `rti`

Interrupt handlers must return with `rti`.

`rts` is for normal subroutines.

### Forgetting to acknowledge the interrupt

For CIA #1, reading `$dc0d` acknowledges the interrupt.

If you do not acknowledge the interrupt, the IRQ request can remain active.

### Forgetting to preserve registers

The CPU does not automatically save A, X, and Y.

If the handler uses them, save and restore them.

### Forgetting that `$fffe/$ffff` are not normally writable ROM

The program writes `$35` to `$01` to bank out BASIC and KERNAL ROM.

That makes the RAM underneath `$fffe/$ffff` writable.

### Confusing interrupt frequency with visible behaviour frequency

The timer interrupt still fires often.

The border changes less often because the handler uses `irq_counter`.

## What comes next

Next lesson:

```text
23 - First raster interrupt
```

Now that we understand a basic IRQ, we can change the interrupt source.

Lesson 22 used:

```text
CIA #1 Timer A
```

Lesson 23 will use:

```text
VIC-II raster interrupt
```

The mechanism is the same:

```text
hardware requests IRQ
CPU jumps through $fffe/$ffff
handler preserves registers
handler acknowledges the source
handler returns with rti
```

Only the source changes.

That is the bridge from general interrupts to raster interrupts.
