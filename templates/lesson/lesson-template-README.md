# Lesson title

> Replace this line with a short one-sentence description of the lesson.

## Goal

Explain the main goal of the lesson in simple terms.

A good goal is concrete. It should describe what the learner will understand or be able to do after completing the lesson.

Example:

> Learn how to build and run a minimal Commodore 64 program from the command line.

## What you will build

Describe the small program, effect, tool, or workflow that this lesson creates.

Keep this section practical. The learner should immediately understand what will exist at the end of the lesson.

Example:

> You will build a tiny C64 program that changes the border colour and keeps the machine running in a simple loop.

## What this teaches

Summarise the learning value of the lesson.

This section should connect the practical result to the deeper concept.

Example:

> This teaches the first direct contact between the CPU and the machine hardware. By writing a value to a memory-mapped hardware register, the program changes something visible on the screen.

## Machine concepts

List and explain the machine-specific ideas introduced in this lesson.

Examples:

- Memory-mapped I/O
- Screen memory
- Colour RAM
- Raster beam
- Hardware sprites
- Display lists
- Bitplanes
- Framebuffer memory

Do not list concepts that are not actually used in the lesson.

## Assembly concepts

List and explain the assembly-language concepts introduced in this lesson.

Examples:

- Immediate values
- Accumulator
- Store instruction
- Labels
- Branches
- Loops
- Addressing modes
- Processor flags

Each new concept should be explained when it first appears.

## Hardware registers used

Document every hardware register used in the lesson.

Use a table when useful.

| Address | Name | Purpose |
| --- | --- | --- |
| `$d020` | VIC-II border colour | Controls the C64 border colour |
| `$d021` | VIC-II background colour | Controls the C64 background colour |

If the lesson does not use hardware registers, say so explicitly.

## Memory addresses used

Document important memory addresses used by the lesson.

| Address | Purpose |
| --- | --- |
| `$0801` | Typical start address for a C64 BASIC-started program |

Explain why each address matters. Do not assume the learner already knows.

## Source files

List the files in this lesson and what each one does.

| File | Purpose |
| --- | --- |
| `main.asm` | Main assembly source file |
| `build.sh` | Build script for macOS/Linux |
| `build.bat` | Build script for Windows, if provided |

Keep the file structure simple in early lessons.

## Code walkthrough

Walk through the code slowly.

Explain each new instruction, label, memory address, and hardware concept.

Do not explain everything at once. Follow the code in the order the machine sees it where possible.

Example structure:

### Program start

Explain where the program starts and how execution reaches the first instruction.

### First instruction

Explain the instruction and why it is needed.

### Hardware write

Explain what address is written to and what visible effect it has.

### Program end or loop

Explain what happens after the visible work is done.

## How to build

Show the exact command needed to build the lesson.

Example:

```bash
./build.sh
```

Explain what output file is created.

Example:

> This creates `build/main.prg`, a Commodore 64 program file that can be loaded in an emulator.

## How to run

Show the exact command or emulator steps needed to run the lesson.

Example:

```bash
x64sc build/main.prg
```

Also explain the expected result.

Example:

> The emulator should start and the C64 border should change colour.

## Experiments

Give the learner small changes to try.

Experiments should be safe, focused, and connected to the lesson goal.

Examples:

1. Change the border colour value.
2. Change only the background colour.
3. Try two different colour values.
4. Remove one instruction and observe what changes.

Each experiment should teach something.

## Common mistakes

List likely mistakes and how to recognise them.

Examples:

- The output file was not created.
- The emulator opens but nothing changes.
- The program exits immediately.
- A hexadecimal value was typed incorrectly.
- A label name does not match.

Explain the symptom and the likely cause.

## What comes next

Briefly explain the next lesson and how it builds on this one.

Example:

> Next, we will look more closely at the CPU itself: the accumulator, registers, flags, and how the processor moves values around.

## Notes

Use this section for additional context, references, or careful limitations.

Keep it focused. Do not turn early lessons into hardware manuals.
