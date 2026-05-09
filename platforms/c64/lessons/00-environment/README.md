# Lesson 00 - Environment and workflow

## Goal

Set up a working Commodore 64 assembly development environment on macOS.

By the end of this lesson, you should have a repeatable workflow for:

- Writing C64 assembly source code
- Assembling it into a `.prg` file
- Running that `.prg` file in a C64 emulator
- Making small changes and trying again
- Keeping local tool paths out of the Git repository

This lesson is about the workflow.

It is not about writing impressive C64 code yet.

## What you will build

You will create the first C64 lesson folder and prepare the environment needed for later lessons.

The folder is:

```text
platforms/c64/lessons/00-environment/
```

The important project-level files and folders for this lesson are:

```text
assembly-from-scratch/
├── .gitignore
└── platforms/
    └── c64/
        ├── tools/
        │   └── kickassembler/
        │       └── KickAss.jar
        └── lessons/
            └── 00-environment/
                └── README.md
```

The `tools/` folder is local to your machine and should not be committed.

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
| Syntax highlighting | KickAss (C64) VS Code extension |
| Assembler | KickAssembler |
| Emulator | VICE |
| Operating system | macOS |
| Version control | Git and GitHub |

## Optional - VS Code syntax highlighting

For syntax highlighting, install the VS Code extension:

```text
KickAss (C64)
```

Marketplace identifier:

```text
CaptainJiNX.kickass-c64
```

This extension helps Visual Studio Code recognise KickAssembler-style C64 assembly files.

It is used only for readability.

The actual build workflow still happens through the terminal, so the learner understands what the assembler and emulator are doing.

## Why these tools?

Visual Studio Code is already part of the project workflow.

KickAssembler is a practical and well-documented C64 assembler. It gives us a clean path from tiny beginner programs to larger C64 projects later.

VICE is the standard Commodore emulator family. It lets us run C64 programs on a modern Mac.

The syntax-highlighting extension makes assembly files easier to read, but it does not replace the command-line workflow.

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

### KickAss (C64) extension

The KickAss (C64) extension helps Visual Studio Code recognise KickAssembler-style assembly files.

It provides syntax highlighting.

It is a reading and editing aid.

It does not assemble the program for us in this project.

We still run the assembler explicitly from the terminal.

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

For this track, we use the C64 emulator called:

```text
x64sc
```

`x64sc` is the more accurate C64 emulator in VICE and is the one we use for this project.

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

Place it somewhere stable on your machine.

For this project, one simple local convention is:

```text
platforms/c64/tools/kickassembler/KickAss.jar
```

This keeps the tool close to the C64 track without committing it to Git.

The exact path may differ on your machine.

That is fine.

What matters is that you know the path to `KickAss.jar`.

## Step 4 - Verify KickAssembler

Run KickAssembler manually first.

Use your own local path:

```bash
java -jar path/to/KickAss.jar
```

Example shape:

```bash
java -jar ~/path/to/assembly-from-scratch/platforms/c64/tools/kickassembler/KickAss.jar
```

If KickAssembler starts and prints usage or version information, the assembler can run.

If the command fails, check:

- Is Java installed?
- Is the path to `KickAss.jar` correct?
- Is the file actually called `KickAss.jar`?
- Did the download extract into a folder with a slightly different structure?

Do not continue until KickAssembler can run from the terminal.

## Step 5 - Add a KickAssembler alias

Typing the full Java command every time is inconvenient.

Add an alias to your shell configuration.

On modern macOS, the default shell is usually `zsh`.

Open the configuration file:

```bash
nano ~/.zshrc
```

Add this line, replacing the path with your own path:

```bash
alias kickass='java -jar ~/path/to/assembly-from-scratch/platforms/c64/tools/kickassembler/KickAss.jar'
```

Save and exit.

In nano:

```text
Ctrl + O
Enter
Ctrl + X
```

Reload the shell configuration:

```bash
source ~/.zshrc
```

Test the alias:

```bash
kickass
```

If KickAssembler starts, the alias works.

## Step 6 - Install VICE

Download VICE for macOS from the official VICE site.

Choose the correct macOS build for your Mac:

- Apple Silicon Mac if you use an M1, M2, M3, or later Mac
- Intel Mac if you use an Intel Mac

For macOS, prefer the GTK3 build.

After installation, open the C64 emulator application:

```text
x64sc.app
```

If macOS blocks it the first time because it is from an unidentified developer:

1. Open **System Settings**
2. Go to **Privacy & Security**
3. Scroll down to the blocked app message
4. Click **Open Anyway**

## Step 7 - Verify VICE

Start `x64sc` from the Applications folder.

If the blue Commodore 64 screen appears, VICE is working.

You can also start it from Terminal with:

```bash
open -a x64sc
```

If that works, create a simple alias.

Open your shell configuration:

```bash
nano ~/.zshrc
```

Add:

```bash
alias x64sc-open='open -a x64sc'
```

Reload:

```bash
source ~/.zshrc
```

Test:

```bash
x64sc-open
```

If the C64 emulator opens, the alias works.

## Step 8 - Install optional syntax highlighting

Install the VS Code extension:

```text
KickAss (C64)
```

Marketplace identifier:

```text
CaptainJiNX.kickass-c64
```

This is optional, but recommended.

It helps make `.asm` files easier to read.

It should not change how the project is built.

## Step 9 - Ignore local tools and macOS metadata

The local tools folder should not be committed to Git.

Generated files and macOS metadata should also be ignored.

Add this to the root `.gitignore` file:

```gitignore
# macOS Finder metadata
.DS_Store

# Local C64 tools
platforms/c64/tools/

# Generated C64 files
*.prg
*.sym
*.dbg
```

This keeps the repository focused on source code and documentation.

## Step 10 - Verify the workflow

At this point, these commands should work from any terminal:

```bash
kickass
x64sc-open
```

The first command starts KickAssembler.

The second command starts the C64 emulator.

That is enough for lesson 00.

The first actual program comes in lesson 01.

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
kickass main.asm
```

This should produce a `.prg` file.

## How to run

There is no lesson program to run yet.

The expected future shape is:

```bash
x64sc-open main.prg
```

Or opening the generated `.prg` file from the VICE application.

## Experiments

Try these before moving on:

- Run `java -version`
- Run KickAssembler manually with `java -jar`
- Add and test the `kickass` alias
- Start VICE from Applications
- Add and test the `x64sc-open` alias
- Install the optional VS Code syntax-highlighting extension
- Add local tools and generated files to `.gitignore`
- Check that `.DS_Store` files do not appear in `git status`

## Common mistakes

### Java is not installed

If `java -version` fails, KickAssembler cannot run yet.

Install Java and try again.

### Wrong path to KickAssembler

If Java works but KickAssembler does not start, the path to `KickAss.jar` is probably wrong.

Use Finder or the terminal to locate the actual jar file.

### Hard-coding someone else's path

Do not copy another person's full local path blindly.

Use the path that matches your own machine.

The alias should point to your local `KickAss.jar`.

### Committing local tools

Do not commit the `platforms/c64/tools/` folder.

That folder is for local convenience.

The repository should contain source code and documentation, not third-party tool binaries.

### VICE opens from Finder, but not from Terminal

Try:

```bash
open -a x64sc
```

If that works, use the `x64sc-open` alias.

### Expecting the VS Code extension to build the project

The syntax-highlighting extension helps with readability.

It does not replace the assembler workflow in this project.

We still build from the terminal so the development loop stays visible.

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
