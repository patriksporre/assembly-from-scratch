# Commodore 64

This is the first platform track in Assembly from Scratch.

The Commodore 64 is the proof of the model: a complete, disciplined learning path from first contact with the machine to increasingly advanced graphics, sound, timing, interrupts, and demoscene-style effects.

The goal is not to write portable assembly code.

The goal is to understand the Commodore 64 on its own terms.

## Why start with the Commodore 64?

The Commodore 64 is a strong first platform because it combines a simple 8-bit CPU with distinctive custom hardware.

It has:

- A 6510 CPU, closely related to the 6502
- The VIC-II graphics chip
- The SID sound chip
- Hardware sprites
- Character modes
- Bitmap modes
- Raster timing
- A large demoscene heritage
- Excellent documentation and tooling

It is simple enough to approach from first principles, but deep enough to reward serious study.

## What we will learn

The C64 track follows the shared Assembly from Scratch learning path:

| Lesson | Topic |
|---|---|
| 00 | Environment and workflow |
| 01 | First contact |
| 02 | CPU basics |
| 03 | Memory map |
| 04 | Screen and display basics |
| 05 | Colour |
| 06 | Text and character output |
| 07 | Graphics primitives |
| 08 | Hardware graphics features |
| 09 | Animation |
| 10 | Timing |
| 11 | Interrupts |
| 12 | Sound |
| 13 | Asset loading |
| 14 | Demoscene building blocks |
| 15 | Advanced effects |
| 99 | Final mini-demo |

Each lesson should build one small piece of understanding.

## C64-specific path

### 00 - Environment and workflow

Set up the development environment.

For the first version of this track, the primary workflow is macOS.

We will use:

- Visual Studio Code as the editor
- A C64 assembler
- The VICE emulator
- Simple build scripts
- Git and GitHub

The goal is to create a repeatable workflow from source code to a running C64 program.

### 01 - First contact

Write the smallest useful program that visibly touches the machine.

On the C64, this means changing the border and background colour.

This introduces:

- `lda`
- `sta`
- Immediate values
- The accumulator
- Memory-mapped I/O
- VIC-II colour registers
- Infinite loops or return behaviour

### 02 - CPU basics

Introduce the 6510 CPU.

This includes:

- Accumulator
- X register
- Y register
- Program counter
- Stack pointer
- Processor status flags
- Addressing modes
- Labels
- Constants
- Simple loops

### 03 - Memory map

Introduce the C64 memory layout.

This includes:

- RAM
- ROM
- I/O
- Zero page
- Screen memory
- Colour RAM
- BASIC and KERNAL areas

The goal is to understand that not all addresses behave like ordinary RAM.

### 04 - Screen and display basics

Introduce the VIC-II and the default character screen.

This includes:

- Character mode
- Screen memory
- Screen codes
- The relationship between memory and visible characters

### 05 - Colour

Introduce the C64 colour system.

This includes:

- Border colour
- Background colour
- Colour RAM
- The C64 palette
- Per-character colour limitations

### 06 - Text and character output

Write text directly to screen memory.

This includes:

- PETSCII
- Screen codes
- Clearing the screen
- Moving text
- Simple messages

### 07 - Graphics primitives

Start with graphics in C64 terms.

This begins with character-based graphics before moving toward custom characters and bitmap modes.

### 08 - Hardware graphics features

Introduce sprites.

This includes:

- Sprite data
- Sprite pointers
- Sprite position
- Sprite colour
- Expansion
- Collision
- Animation

### 09 - Animation

Make things move.

This includes:

- Updating values over time
- Frame loops
- Delay loops
- Simple movement
- Speed control
- Basic synchronisation

### 10 - Timing

Introduce the raster beam and the frame.

This includes:

- Scanlines
- Frames
- Waiting for raster positions
- Cycle awareness
- Why timing matters on old machines

### 11 - Interrupts

Introduce raster interrupts.

This includes:

- IRQ setup
- Interrupt vectors
- Acknowledging interrupts
- Preserving registers
- Returning from interrupts
- Split screens
- Music playback timing

### 12 - Sound

Introduce the SID chip.

This includes:

- Voices
- Frequency
- Waveforms
- Volume
- ADSR envelopes
- Simple sound effects
- Music playback later

### 13 - Asset loading

Introduce external data.

This includes:

- Sprite data
- Character sets
- Pictures
- SID files later
- Disk image basics later if needed

### 14 - Demoscene building blocks

Introduce recognisable C64 demo techniques.

This includes:

- Sine tables
- Colour cycling
- Character effects
- Scrollers
- Raster bars
- Sprite multiplexing

### 15 - Advanced effects

Move toward more demanding effects.

This includes:

- Plasma
- DYCP
- Bitmap effects
- FLI-like ideas
- Sideborder tricks
- Performance constraints

### 99 - Final mini-demo

Build a small complete C64 demo.

It may include:

- Intro screen
- Logo
- Music
- Scroller
- Raster effects
- Sprite animation
- Simple transitions

The goal is not to create a competition-winning demo.

The goal is to combine what the track has taught.

## Style for this platform

Early C64 lessons should stay close to the hardware.

That means:

- Raw addresses before symbolic constants
- No macros in early lessons
- No helper libraries in early lessons
- No unexplained include files
- Clear comments that teach
- One new concept at a time

The first time an instruction appears, it should be explained.

The first time a hardware address appears, it should be explained.

The first time a C64 concept appears, it should be connected to something visible or practical.

## Tooling note

The first version of the C64 track will document a macOS workflow.

Later, we may add notes for Windows and Linux.

The initial toolchain will be decided in lesson 00.
