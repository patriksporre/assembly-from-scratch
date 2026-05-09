# Learning path

Assembly from Scratch follows one shared learning path across multiple classic computers.

The purpose is to make the journey comparable without making the machines artificially similar.

Each platform should move through the same broad stages: environment, first contact, CPU, memory, display, colour, text, graphics, animation, timing, interrupts, sound, assets, demo effects, and a final mini-demo.

The first platform is the Commodore 64. Later platform tracks may include Atari 800, Atari 520ST, Amiga 500, and DOS VGA.

## Why a shared path exists

A shared path gives the project discipline.

It helps each platform track answer the same learning questions:

- How do we build and run code for this machine?
- How do we make first contact with the hardware?
- What does the CPU actually do?
- How is memory organised?
- How does the machine display characters, pixels, colour, and movement?
- How does timing work?
- How do interrupts work?
- How does the machine produce sound?
- How are assets represented and loaded?
- How do demo effects emerge from the hardware?

The path is shared.

The answers are machine-specific.

## The learning sequence

### 00 - Environment and workflow

Set up the basic development workflow.

This includes the editor, assembler, emulator, build scripts, repository structure, and a repeatable way to build and run programs.

The goal is not to write impressive code. The goal is to make sure the learner can go from source code to a running program with confidence.

Typical topics:

- Editor setup
- Assembler setup
- Emulator setup
- Folder structure
- Build scripts
- Generated files
- Git workflow
- Running the first empty or minimal program

### 01 - First contact

Write the smallest useful program that visibly touches the machine.

On the Commodore 64, this means changing the border or background colour. On DOS VGA, it may mean switching to a graphics mode and plotting a pixel. On another machine, it may mean changing a palette register or clearing a screen.

The goal is to experience the link between code, memory, hardware, and visible output.

Typical topics:

- A minimal program
- A visible hardware effect
- Loading a value
- Storing a value
- Immediate values
- Memory-mapped I/O or equivalent hardware access
- Looping or returning cleanly

### 02 - CPU basics

Introduce the CPU as the part of the machine that executes instructions.

The goal is to understand the main registers, flags, addressing modes, and the basic rhythm of instruction execution.

This lesson should stay close to concrete examples. The learner should see how a small number of instructions move data, make decisions, and repeat work.

Typical topics:

- CPU registers
- Accumulator or general-purpose registers
- Index registers or address registers
- Program counter
- Stack pointer
- Status flags or condition codes
- Addressing modes
- Labels
- Constants
- Simple loops

### 03 - Memory map

Introduce the machine's memory layout.

The goal is to understand that memory is not just a large anonymous space. On classic computers, different address ranges often mean different things: RAM, ROM, I/O registers, screen memory, colour memory, system areas, and special-purpose regions.

Typical topics:

- RAM
- ROM
- I/O area
- Zero page or low memory where relevant
- Screen memory
- Colour memory or palette memory where relevant
- System vectors
- Why some addresses behave differently from normal RAM

### 04 - Screen and display basics

Introduce how the machine puts something on screen.

The goal is to understand the default or simplest display mode before moving into richer graphics.

On the C64 this starts with character mode and screen memory. On the Atari 800 this involves ANTIC and display lists. On the Amiga and Atari ST this leads toward bitplanes. On DOS VGA this starts with direct video memory.

Typical topics:

- Display hardware overview
- Default screen mode
- Screen memory
- Character cells, pixels, bitplanes, or framebuffer depending on platform
- How memory becomes visible output
- Basic screen clearing

### 05 - Colour

Introduce how the machine represents colour.

The goal is to separate the idea of visible shape from the idea of colour. Many classic machines store these separately or impose strong constraints on how colour can be used.

Typical topics:

- Border colour where relevant
- Background colour
- Palette registers
- Colour RAM or colour attributes
- Per-character, per-line, per-sprite, or per-pixel colour limits
- Why colour constraints shape graphics style

### 06 - Text and character output

Write text to the screen without hiding the mechanism too early.

The goal is not merely to print words. The goal is to understand how text is represented, where it is stored, and how the display hardware turns memory into characters.

Typical topics:

- Character codes
- Screen codes versus text encodings where relevant
- Writing characters directly to screen memory
- Clearing text
- Moving text
- Simple messages
- Character layout

### 07 - Graphics primitives

Introduce the first simple graphical building blocks.

The exact meaning depends on the platform. On the C64 this may begin with character-based graphics before bitmap mode. On DOS VGA it may mean plotting pixels and lines. On bitplane machines it may mean understanding how pixels are packed into memory.

Typical topics:

- Plotting concepts
- Character-based graphics
- Pixels where appropriate
- Lines or simple shapes
- Bitmap memory layout where appropriate
- Why graphics memory layout matters

### 08 - Hardware graphics features

Introduce the machine's special graphics hardware.

This stage should respect the machine. Each platform has its own answer.

Typical platform examples:

- Commodore 64: sprites
- Atari 800: player/missile graphics and display lists
- Atari 520ST: bitplanes, palette changes, software sprites
- Amiga 500: copper, blitter, sprites, bitplanes
- DOS VGA: palette, framebuffer, page flipping, VGA registers

Typical topics:

- What the hardware feature does
- Where its data lives
- Which registers control it
- What limitations it has
- What creative possibilities it opens

### 09 - Animation

Make something move.

The goal is to understand that animation is repeated change over time. The learner should see how values are updated frame by frame and how the machine redraws or reuses display data.

Typical topics:

- Position values
- Updating memory or hardware registers
- Frame loops
- Delay loops
- Simple movement
- Direction and bounds
- Flicker and speed problems

### 10 - Timing

Introduce the connection between code and the display timing of the machine.

The goal is to understand that old computers are often closely tied to the raster beam, frame rate, scanlines, vertical blanking, or hardware refresh cycle.

Typical topics:

- Frames
- Scanlines or vertical blanking
- Raster beam where relevant
- Waiting for a safe moment
- Cycle awareness
- Why uncontrolled timing causes unstable output
- Why timing becomes part of the art

### 11 - Interrupts

Introduce interrupts as a way for the machine to respond to events or run code at controlled times.

The goal is to understand what interrupts are, why they matter, and how they support stable animation, raster effects, music playback, and system behaviour.

Typical topics:

- What an interrupt is
- Interrupt vectors or handlers
- Acknowledging interrupts
- Vertical blank interrupts
- Raster interrupts or display list interrupts where relevant
- Preserving registers
- Returning from an interrupt

### 12 - Sound

Introduce sound hardware.

The goal is to understand sound as controlled hardware state, not as an abstract audio file.

Each platform should approach sound through its own hardware and culture.

Typical topics:

- Sound chip overview
- Voices or channels
- Frequency or period values
- Volume
- Waveforms or samples
- Envelopes
- Simple sound effects
- Music playback later

### 13 - Asset loading

Introduce external data.

The goal is to understand how graphics, character sets, sprites, music, pictures, and other assets are represented and brought into a program.

This should be introduced only after the learner understands what the data means in memory.

Typical topics:

- Binary data
- Including data in source files
- Loading data into memory
- Character sets
- Sprite data
- Pictures
- Music data
- Disk images where relevant

### 14 - Demoscene building blocks

Introduce the classic building blocks of demo effects.

The goal is to connect earlier lessons into recognisable demoscene techniques.

These are not magic tricks. They are consequences of understanding the CPU, memory, display hardware, timing, and sound.

Typical topics:

- Sine tables
- Colour cycling
- Raster bars
- Scrollers
- Character effects
- Sprite multiplexing
- Palette effects
- Copper effects where relevant
- Software-rendered effects where relevant

### 15 - Advanced effects

Move toward more ambitious effects.

The goal is to show how deep hardware understanding, careful timing, data layout, and creative constraints combine into advanced visual techniques.

Typical topics:

- Plasma
- Fire
- Tunnels
- DYCP
- Bitmap effects
- Bitplane tricks
- Fullscreen or border tricks where relevant
- Blitter objects where relevant
- Performance constraints
- Trade-offs between quality, speed, and memory

### 99 - Final mini-demo

Build a small complete demo for the platform.

The goal is not to produce a competition-winning demo. The goal is to combine the lessons into a coherent artefact.

A final mini-demo may include:

- Intro screen
- Logo or title
- Music or sound
- Scroller
- Animated object
- Raster, palette, or display effect
- Simple transitions
- Clean build and run instructions

The final mini-demo should show that the learner understands the machine well enough to combine multiple systems with intention.

## How each lesson should work

Each lesson should be small enough to understand, build, run, modify, and commit.

Every lesson should include:

- Goal
- What you will build
- What this teaches
- Machine concepts
- Assembly concepts
- Hardware registers used
- Memory addresses used
- Code walkthrough
- How to build
- How to run
- Experiments
- Common mistakes
- What comes next

## How the path should be used

This path is a guide, not a prison.

Some platforms may need extra lessons. Some may merge topics. Some may require a different local order because of how the hardware works.

That is acceptable.

The important rule is that the learning path remains disciplined:

- Start from the environment
- Make visible contact with the machine
- Understand the CPU
- Understand memory
- Understand display
- Add movement
- Add timing
- Add interrupts
- Add sound
- Add assets
- Build toward demo effects
- Finish with a small complete artefact

## The standard

The learner should never have to accept that something works by magic.

By the end of each lesson, the learner should know:

- What was built
- Why it works
- Which parts of the machine were touched
- Which assembly concepts were introduced
- What can be changed safely
- What remains unclear
- What comes next

That is the path.

