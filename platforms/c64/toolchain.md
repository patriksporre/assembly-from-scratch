# C64 toolchain

This document records the initial toolchain decision for the Commodore 64 track.

The goal is to create a simple, repeatable workflow for writing C64 assembly on macOS, building it into a C64 program, and running it in an emulator.

This document explains the toolchain choice.

The exact installation steps belong in:

```text
platforms/c64/lessons/00-environment/
```

## Initial toolchain

The first version of the C64 track uses:

| Purpose | Tool |
|---|---|
| Editor | Visual Studio Code |
| Assembler | KickAssembler |
| Emulator | VICE |
| Operating system | macOS first |
| Version control | Git and GitHub |

## Why this toolchain?

The first toolchain should be practical, stable, well-documented, and beginner-friendly.

It should let us focus on the Commodore 64 instead of fighting the environment.

The toolchain should also work well for a lesson-based project where every step is explained and committed.

## Editor: Visual Studio Code

Visual Studio Code is the editor for this project.

It is already part of the project workflow and works well for:

- Markdown documentation
- Assembly source files
- Integrated terminal usage
- Git integration
- Project navigation
- Simple build commands

The editor should remain a support tool.

It should not hide what the build process does.

## Assembler: KickAssembler

KickAssembler is the initial assembler for the C64 track.

Reasons:

- It is widely used in modern C64 development.
- It is readable.
- It is well-documented.
- It works from the command line.
- It supports larger projects later.
- It runs on Java, which makes it practical across operating systems.
- It gives us room to grow into more advanced work when we are ready.

Important discipline:

We will not use KickAssembler's advanced features too early.

Early lessons should avoid:

- Macros
- Helper libraries
- Clever scripting
- Unexplained include files
- Abstracted hardware access

KickAssembler gives us power, but we will deliberately start with simple assembly.

The project principle still applies:

```text
Nothing is hidden too early.
```

## Emulator: VICE

VICE is the initial emulator for the C64 track.

Reasons:

- It is the standard Commodore emulator family.
- It supports the C64 and other Commodore machines.
- It is actively maintained.
- It provides macOS builds.
- It supports both simple running and more advanced debugging workflows later.

For the first lessons, VICE is used simply to run the generated C64 program.

Later, we may use more advanced emulator features such as:

- Monitor/debugger
- Memory inspection
- Breakpoints
- Register inspection
- Raster timing investigation

Those features should be introduced only when the lessons need them.

## macOS first

The first version of the C64 track documents a macOS workflow.

That means lesson 00 should explain how to set up and verify the workflow on a Mac.

Later, the project may add notes for:

- Windows
- Linux

But the first path should stay clean and focused.

## Expected workflow

The basic workflow should become:

```text
Write assembly source
        |
        v
Run assembler
        |
        v
Generate .prg file
        |
        v
Run .prg in VICE
        |
        v
Observe result
        |
        v
Change code and repeat
```

In practical terms, a later lesson may use commands similar to:

```bash
java -jar path/to/KickAss.jar main.asm
x64sc main.prg
```

The exact commands will depend on where the tools are installed and how we choose to organise the lesson folders.

## Generated files

Generated files should not be committed unless there is a clear reason.

Examples of generated files:

- `.prg`
- temporary build files
- emulator output
- debug symbols, unless needed for a lesson

The repository should focus on source code and documentation.

A `.gitignore` file will be added when the build workflow is defined.

## Alternative assemblers

ACME is also a strong C64 assembler and remains a valid alternative.

For this project, KickAssembler is chosen first because it is approachable, well-documented, and gives us a smooth path from beginner lessons to larger demo-style projects.

We may revisit assembler choices later if needed.

The choice of assembler should never become more important than the learning goal.

## Toolchain principle

The toolchain should help the learner reach the machine.

It should not become the lesson itself.

The important thing is not that we use KickAssembler or VICE.

The important thing is that the learner understands:

- What source code is
- What the assembler produces
- What a `.prg` file is
- How the emulator loads it
- What the C64 does when the program runs
- How a visible result connects back to a specific instruction and memory address

That is the standard for this toolchain.
