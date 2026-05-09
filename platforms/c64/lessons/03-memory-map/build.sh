#!/usr/bin/env bash
set -e

java -jar ../../tools/kickassembler/KickAss.jar main.asm

open -a x64sc main.prg