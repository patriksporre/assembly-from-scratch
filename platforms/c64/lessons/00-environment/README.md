# Lesson 00 - Environment and workflow

## Goal

Set up a working Commodore 64 assembly development environment on macOS.

By the end of this lesson, you should have a repeatable workflow for:

- Writing C64 assembly source code
- Assembling it into a `.prg` file
- Running that `.prg` file in a C64 emulator
- Making small changes and trying again
- Committing the lesson structure to Git

This lesson is about the workflow.

It is not about writing impressive C64 code yet.

## What you will build

You will create the first C64 lesson folder and prepare the environment needed for later lessons.

The folder will eventually contain:

```text
platforms/c64/lessons/00-environment/
├── README.md
├── main.asm
├── build.sh
└── .gitignore
```

In this lesson, we focus first on installing and verifying the tools.

The first visible C64 program comes in lesson 01.

## What this teaches

This lesson teaches the development loop.

The basic loop is:

```text
Write source code
        |
        v
Assemble source code
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

This loop matters because every later lesson depends on it.

Before we learn the CPU, memory map, VIC-II, sprites, raster timing, or SID, we need to know how to get code running.

## Tools

For the first version of the C64 track, we use:

| Purpose | Tool |
|---|---|
| Editor | Visual Studio Code |
| Assembler | KickAssembler |
| Emulator | VICE |
| Operating system | macOS |
| Version control | Git and GitHub |

## Why these tools?

Visual Studio Code is already part of the project workflow.

KickAssembler is a practical and well-documented C64 assembler. It gives us a clean path from tiny beginner programs to larger C64 projects later.

VICE is the standard Commodore emulator family. It lets us run C64 programs on a modern Mac.

The important point is not the tools themselves.

The important point is that the learner understands what each tool does.

## What each tool does

### Visual Studio Code

Visual Studio Code is where we write and edit files.

In this project, it is used for:

- Markdown documentation
- Assembly source files
- Terminal commands
- Git workflow
- Project navigation

Visual Studio Code does not make the program run by itself.

It is the workshop, not the machine.

### KickAssembler

KickAssembler turns assembly source code into a C64 program file.

The source file might be called:

```text
main.asm
```

The generated C64 program file might be called:

```text
main.prg
```

The assembler reads the instructions we write and produces bytes the C64 can load and execute.

### VICE

VICE emulates the Commodore 64.

It lets a modern Mac behave like a C64 closely enough for development and learning.

For this track, we will normally use the C64 emulator called:

```text
x64sc
```

The name means a more accurate C64 emulator within VICE.

## Step 1 - Create the lesson folder

From the repository root, create the lesson folder:

```bash
mkdir -p platforms/c64/lessons/00-environment
```

Then create the README file:

```bash
touch platforms/c64/lessons/00-environment/README.md
```

This file is the README you are reading now.

## Step 2 - Install Java

KickAssembler runs on Java.

Check whether Java is already installed:

```bash
java -version
```

If Java is installed, you should see version information.

If Java is not installed, install a current Java runtime for macOS.

A common Mac approach is to use Homebrew:

```bash
brew install --cask temurin
```

After installation, close and reopen the terminal if needed, then check again:

```bash
java -version
```

The exact Java version is less important than having a working Java runtime that can run KickAssembler.

## Step 3 - Download KickAssembler

Download KickAssembler from the official KickAssembler site.

After downloading, place it somewhere stable on your machine.

A simple option is:

```text
~/c64/tools/KickAssembler/
```

Inside that folder, you should have the KickAssembler jar file, commonly named:

```text
KickAss.jar
```

The exact folder is your choice.

What matters is that you know the path to the jar file.

Example path:

```text
~/c64/tools/KickAssembler/KickAss.jar
```

## Step 4 - Verify KickAssembler

Run this command, adjusting the path if needed:

```bash
java -jar ~/c64/tools/KickAssembler/KickAss.jar
```

If KickAssembler starts and prints usage or version information, the assembler can run.

If the command fails, check:

- Is Java installed?
- Is the path to `KickAss.jar` correct?
- Is the file actually called `KickAss.jar`?
- Did the download extract into a folder with a slightly different structure?

Do not continue until KickAssembler can run from the terminal.

## Step 5 - Install VICE

Download VICE for macOS from the official VICE site.

Choose the correct macOS build for your Mac:

- Apple Silicon Mac if you use an M1, M2, M3, or later Mac
- Intel Mac if you use an Intel Mac

For macOS, prefer the GTK3 build.

After installation, locate the C64 emulator executable.

Depending on how VICE is packaged and installed, the executable may be available as an application or as a command-line program.

The command-line C64 emulator we want later is usually:

```text
x64sc
```

## Step 6 - Verify VICE

Try to start VICE.

If `x64sc` is available in your terminal path, this may work:

```bash
x64sc
```

If it opens the C64 emulator, VICE is working.

If the terminal cannot find `x64sc`, VICE may still be installed correctly, but the command-line executable is not in your path.

That is acceptable for now.

In lesson 01, we can either:

- run the `.prg` file from the VICE application, or
- add the VICE executable folder to the shell path, or
- create a build script that points directly to the emulator

For now, the goal is simply to confirm that VICE runs.

## Step 7 - Create a place for local tool paths

We do not want to hard-code Patrik's local machine paths into lesson files that everyone else will use.

For example, this path is local to one machine:

```text
/Users/patrik/c64/tools/KickAssembler/KickAss.jar
```

A future build script may need a way to handle local configuration.

For the first version, we can keep it simple and document the expected paths.

Later, if needed, we can add a local configuration file that is ignored by Git.

## Step 8 - Git ignore generated files

Generated C64 program files should usually not be committed.

Create this file in the lesson folder:

```bash
touch platforms/c64/lessons/00-environment/.gitignore
```

Add this content:

```gitignore
*.prg
*.sym
*.dbg
```

This keeps generated files out of Git unless we deliberately decide to include them.

## Machine concepts

This lesson does not yet introduce C64 hardware concepts deeply.

It only introduces the idea that C64 development has three separate stages:

1. Source code is written on the modern machine.
2. The assembler converts source code into a C64 program file.
3. The emulator runs that program as if it were on a C64.

The C64 itself will enter the picture properly in lesson 01.

## Assembly concepts

This lesson does not yet teach assembly instructions.

That is deliberate.

Before learning instructions, we need a stable way to build and run them.

Lesson 01 will introduce the first actual instructions:

- `lda`
- `sta`

## Hardware registers used

None.

## Memory addresses used

None.

## Code walkthrough

No C64 code is required in this lesson yet.

A minimal `main.asm` may be added later only to verify the toolchain, but the first meaningful program belongs in lesson 01.

## How to build

There is no program to build yet.

The build workflow will be introduced once `main.asm` exists.

The expected future shape is:

```bash
java -jar path/to/KickAss.jar main.asm
```

This should produce a `.prg` file.

## How to run

There is no lesson program to run yet.

The expected future shape is:

```bash
x64sc main.prg
```

Or opening the generated `.prg` file from the VICE application.

## Experiments

Try these before moving on:

- Run `java -version`
- Run KickAssembler from the terminal
- Start VICE
- Find where `x64sc` is located on your Mac
- Create the `00-environment` lesson folder
- Add the `.gitignore` file
- Commit the lesson README

## Common mistakes

### Java is not installed

If `java -version` fails, KickAssembler cannot run yet.

Install Java and try again.

### Wrong path to KickAssembler

If Java works but KickAssembler does not start, the path to `KickAss.jar` is probably wrong.

Use Finder or the terminal to locate the actual jar file.

### VICE opens, but `x64sc` does not work in the terminal

This usually means VICE is installed, but its command-line tools are not in your shell path.

That is not fatal.

We can solve it later.

### Trying to learn everything at once

Do not turn lesson 00 into a full C64 programming lesson.

The goal is only to make the development loop possible.

## What comes next

Next lesson:

```text
01 - First contact
```

In that lesson, we will write the first meaningful C64 program.

It will change the border and background colour.

That tiny program will introduce the first real bridge between assembly code and the C64 hardware.
