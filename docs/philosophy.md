# Philosophy

Assembly from Scratch is a step-by-step learning project for understanding classic computers and assembly programming from first principles.

The goal is not only to learn assembly language. The goal is to understand how real machines work.

Each platform is treated as its own machine, with its own CPU, memory map, display hardware, sound hardware, timing model, strengths, limitations, and creative possibilities.

The first platform is the Commodore 64. Later tracks may include Atari 800, Atari 520ST, Amiga 500, and DOS VGA.

## The goal is understanding

This project is not about portability.

It is not about hiding old machines behind modern abstractions.

It is not about writing the shortest possible code.

It is not about using clever tricks before the foundation is clear.

The goal is understanding.

Every instruction should earn its place.

Every register should be explained.

Every memory address should mean something.

Every lesson should reveal one more part of how the machine works.

## One learning architecture, multiple platform tracks

The project uses one shared learning structure across multiple classic platforms.

Each platform should move through the same broad path:

- Environment and workflow
- First contact
- CPU basics
- Memory map
- Screen and display basics
- Colour
- Text and character output
- Graphics primitives
- Hardware graphics features
- Animation
- Timing
- Interrupts
- Sound
- Asset loading
- Demoscene building blocks
- Advanced effects
- Final mini-demo

This makes the platforms comparable without making them artificially similar.

The shared part is the learning model.

The machine-specific part is the code, the hardware, the memory map, the tooling, the constraints, and the character of the machine.

## No false portability

The code should not pretend that all machines are the same.

A Commodore 64 is not an Atari 800.

An Atari ST is not an Amiga.

DOS VGA is not a C64 with more memory.

Each machine has its own way of thinking.

The project should reveal those differences, not hide them.

There should be no generic abstraction layer that smooths away the hardware too early. If a machine has sprites, we learn sprites. If a machine has display lists, we learn display lists. If a machine uses bitplanes, we learn bitplanes. If a machine gives us a framebuffer, we learn what that means.

The point is not to make the code portable.

The point is to make the learner more capable.

## Nothing is hidden too early

Early lessons should be explicit.

That means:

- No macros in the beginning
- No helper libraries in the beginning
- No unexplained include files
- No clever shortcuts
- No magic constants without explanation
- No code that works without saying why

At first, we write directly to the machine.

For example, on the Commodore 64, an early lesson may write directly to the VIC-II border colour register:

```asm
lda #$06        ; Load the value 6 into the accumulator.
sta $d020       ; Store it in the VIC-II border colour register.
```

This is deliberately raw.

Later, once the learner understands what `$d020` is, the code can become more structured:

```asm
VIC_BORDER_COLOUR = $d020

lda #BLUE
sta VIC_BORDER_COLOUR
```

Structure is introduced only after the learner understands what the structure replaces.

## Code should teach

The code in this project should be simple, explicit, beautiful, and heavily documented.

Comments should teach, not decorate.

A comment should explain why something matters, what the machine is doing, or what the learner should notice.

Poor comment:

```asm
lda #$06        ; Load 6
```

Better comment:

```asm
lda #$06        ; Put colour value 6 into the accumulator.
```

Even better when the concept is first introduced:

```asm
lda #$06        ; Load the immediate value $06 into the accumulator.
                ; The accumulator is the main 8-bit working register of the 6510 CPU.
```

As the lessons progress, comments can become lighter because earlier lessons have already explained the foundation.

## Every lesson should have a clear purpose

Each lesson should answer four questions:

1. What are we building?
2. What machine concept does it reveal?
3. What assembly concepts do we learn?
4. What can the learner experiment with?

A lesson should not add complexity just to look impressive.

A lesson should add one meaningful piece of understanding.

Small steps are not a weakness. They are the method.

## Respect the machine

Classic computers are not primitive versions of modern computers.

They are coherent machines with specific trade-offs.

The Commodore 64 has the VIC-II and SID.

The Atari 800 has ANTIC, GTIA, POKEY, and display lists.

The Atari ST has the Motorola 68000, Shifter, and a different 16-bit design philosophy.

The Amiga 500 has the 68000, copper, blitter, bitplanes, sprites, and Paula audio.

DOS VGA has x86, video memory, VGA registers, palettes, and software rendering.

Each platform should be studied with respect.

The constraints are not obstacles to skip over. They are the source of the creativity.

## Respect demoscene heritage

This project should eventually build toward demoscene-style effects.

But it should not start there.

Raster bars, scrollers, sine tables, sprite multiplexing, copper lists, bitplane tricks, plasma, fire, tunnels, and other effects only become meaningful when the learner understands the machine underneath them.

The demoscene is not just a collection of tricks.

It is a culture of understanding hardware deeply enough to make it do things it was never obviously designed to do.

That is the spirit this project should respect.

## Slow is good

This is a long journey.

The project should move from beginner to advanced and eventually toward elite-level understanding.

That requires patience.

We should not rush from a first border colour program to interrupts, sprites, music, and plasma before the foundations are solid.

The correct rhythm is:

- Build something small
- Explain it clearly
- Experiment with it
- Understand what changed
- Commit it
- Move on

Bite-sized progress is still progress.

## The final standard

A good lesson in this project should make the learner feel:

- I know what this code does.
- I know why this memory address matters.
- I know what the CPU is doing.
- I know what the hardware is doing.
- I know what I can change.
- I know what I do not understand yet.
- I know what comes next.

That is the standard.

Not speed.

Not cleverness.

Understanding.