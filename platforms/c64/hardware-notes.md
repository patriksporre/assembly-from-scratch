# C64 hardware notes

This document is a lightweight orientation to the Commodore 64 hardware.

It is not a complete hardware reference.

The purpose is to give the C64 track a stable starting point and a shared vocabulary before the lessons begin.

The details will be introduced slowly, lesson by lesson.

## The machine at a glance

The Commodore 64 is an 8-bit home computer built around a CPU and several important support chips.

The most important parts for this project are:

| Part | Role |
|---|---|
| 6510 CPU | Executes the program instructions |
| VIC-II | Produces video output |
| SID | Produces sound |
| CIA chips | Handle timers, keyboard, joystick, serial I/O, and other system tasks |
| RAM | Stores program code, data, screen memory, and other working state |
| ROM | Contains BASIC and KERNAL system routines |
| I/O area | Contains hardware registers used to control chips |

The C64 is not understood by looking at the CPU alone.

The machine is understood by looking at how the CPU, memory map, video hardware, sound hardware, and timing model work together.

## CPU: 6510

The C64 uses the MOS Technology 6510 CPU.

The 6510 is closely related to the 6502.

For early lessons, the most important CPU concepts are:

- The accumulator
- The X register
- The Y register
- The program counter
- The stack pointer
- The processor status flags
- Addressing modes
- Loading values
- Storing values
- Branching and looping

The CPU executes instructions one at a time.

It does not know what a border colour, sprite, character, or sound is.

It only reads and writes memory.

The magic of the C64 is that some memory addresses are connected to hardware.

## Memory-mapped I/O

One of the most important ideas in C64 programming is memory-mapped I/O.

This means that some memory addresses do not behave like ordinary RAM.

When the CPU writes to certain addresses, it is not just storing data.

It is controlling hardware.

For example, the VIC-II border colour register is at:

```text
$d020
```

Writing a value to `$d020` changes the border colour.

That means a tiny program like this can visibly affect the machine:

```asm
lda #$06
sta $d020
```

This is the first major bridge between assembly code and the physical machine.

## VIC-II

The VIC-II is the C64 video chip.

It is responsible for generating the image seen on screen.

It controls or participates in:

- Border colour
- Background colour
- Character display
- Bitmap display
- Sprites
- Raster position
- Screen memory interpretation
- Display timing

The VIC-II is central to C64 graphics and demoscene effects.

Early lessons will start with simple colour registers.

Later lessons will introduce character mode, screen memory, sprites, raster timing, interrupts, and more advanced effects.

## SID

The SID is the C64 sound chip.

It is responsible for sound generation.

It provides:

- Three voices
- Waveforms
- Frequency control
- Pulse width control
- ADSR envelopes
- Filters
- Volume control

SID programming will come later, after the learner has a stronger foundation in memory, registers, timing, and hardware access.

The goal is to understand sound as hardware state, not as an abstract audio file.

## CIA chips

The C64 contains two CIA chips.

CIA stands for Complex Interface Adapter.

The CIAs are used for system tasks such as:

- Keyboard input
- Joystick input
- Timers
- Interrupt support
- Serial bus communication
- Other I/O duties

The CIA chips are important, but they do not need to be understood all at once.

They will be introduced when the lessons require them.

## RAM and ROM

The C64 has RAM and ROM.

RAM is writable memory.

ROM contains fixed system code, including BASIC and KERNAL routines.

The C64 memory map is not a simple flat space where every address always means ordinary RAM.

Some address ranges may refer to RAM, ROM, or I/O depending on configuration.

This is one reason the memory map deserves its own lesson.

## Screen memory

In the default C64 character screen, the visible characters are controlled by screen memory.

A common default screen memory area starts at:

```text
$0400
```

Writing character codes into this area changes what appears on the screen.

Colour is not stored in the same place as the character.

Colour RAM is separate.

This separation is one of the important early C64 concepts.

## Colour RAM

Colour RAM controls the colour of character cells.

It is separate from screen memory.

A common colour RAM area starts at:

```text
$d800
```

This means that, in the default character mode, a character and its colour are controlled by different memory areas.

This is different from many modern graphics models and is part of what gives the C64 its character.

## Raster beam and timing

The C64 display is drawn over time.

The VIC-II generates the screen line by line.

This is often described as the raster beam.

Understanding the raster beam is essential for:

- Stable animation
- Waiting for safe screen updates
- Raster bars
- Split screens
- Raster interrupts
- Sprite multiplexing
- Many demoscene effects

Timing is not an advanced detail.

Timing is part of how the machine works.

We will introduce it carefully.

## Sprites

The C64 has hardware sprites.

Sprites are movable graphic objects controlled by the VIC-II.

They are useful for:

- Characters
- Objects
- Logos
- Effects
- Animation

Sprites have their own data, position registers, colour settings, and limitations.

They will be introduced after the learner understands basic display memory and colour.

## Important early addresses

These addresses will appear early in the C64 track.

They are listed here only as orientation.

They will be properly explained when first used.

| Address | Meaning |
|---|---|
| `$d020` | VIC-II border colour register |
| `$d021` | VIC-II background colour register |
| `$0400` | Common default screen memory start |
| `$d800` | Colour RAM start |

Do not memorise these yet.

The lessons will make them meaningful.

## How to read this document

This file is not a lesson.

It is a map.

The lessons will walk through the territory slowly.

When a register, memory address, or chip becomes important, it should be explained in the lesson where it first appears.

The learner should never have to accept that something works by magic.
