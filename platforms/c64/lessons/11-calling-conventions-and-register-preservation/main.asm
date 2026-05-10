// Assembly from Scratch
// Platform: Commodore 64
// Lesson 11: Calling conventions and register preservation
//
// This lesson introduces calling conventions.
//
// A subroutine can change CPU registers.
// If the caller expects a register to survive a subroutine call,
// either the caller must save it or the subroutine must preserve it.
//
// The routine itself is not important here.
// The contract between caller and routine is important.
//
// Project convention from this lesson:
//
//   A, X, Y, and flags may be destroyed unless the routine says otherwise.
//   The caller saves what it needs.
//   The callee preserves only what it explicitly promises to preserve.
//
// Every non-trivial routine should document:
//
//   input
//   output
//   destroyed registers
//   preserved registers, if any
//   memory locations used

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

.encoding "screencode_upper"  // Convert .text strings to C64 uppercase screen codes

start:
    lda #$06                  // Load colour value $06, blue
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

    jsr clear_screen          // Prepare a clean screen

// -----------------------------------------------------------------------------
// Case 1: caller assumes X survives, but it does not
// -----------------------------------------------------------------------------

    ldx #$00                  // Caller wants to use X as a screen offset

    lda #$01                  // Load screen code $01, the letter A
    sta $0400,x               // Write A at $0400 + X

    jsr destroys_x            // This routine destroys X

    lda #$02                  // Load screen code $02, the letter B
    sta $0401,x               // Caller expected X to still be $00

// -----------------------------------------------------------------------------
// Case 2: caller saves X before calling a routine that destroys it
// -----------------------------------------------------------------------------

    ldx #$00                  // Caller wants X to survive the call

    lda #$03                  // Load screen code $03, the letter C
    sta $0428,x               // Write C at row 1, column 0

    txa                       // Copy X into A
    pha                       // Push A onto the stack

    jsr destroys_x            // This routine destroys X

    pla                       // Pull saved X value back into A
    tax                       // Restore X

    lda #$04                  // Load screen code $04, the letter D
    sta $0429,x               // Write D at row 1, column 1 as expected

// -----------------------------------------------------------------------------
// Case 3: callee preserves X internally
// -----------------------------------------------------------------------------

    ldx #$00                  // Caller wants X to survive the call

    lda #$05                  // Load screen code $05, the letter E
    sta $0450,x               // Write E at row 2, column 0

    jsr preserves_x           // This routine preserves X

    lda #$06                  // Load screen code $06, the letter F
    sta $0451,x               // Write F at row 2, column 1 as expected

    rts                       // Return to BASIC

// -----------------------------------------------------------------------------
// Clear screen subroutine
// -----------------------------------------------------------------------------
//
// Input:
//
//   none
//
// Output:
//
//   screen memory filled with spaces
//   colour RAM initialised to white
//
// Destroys:
//
//   A
//   X
//   flags
//
// Preserves:
//
//   Y
//
// Memory used:
//
//   $0400-$07ff
//   $d800-$dbff

clear_screen:
    ldx #$00                  // Start X at zero

clear:
    lda #$20                  // Load screen code $20, space
    sta $0400,x               // Clear screen page $04
    sta $0500,x               // Clear screen page $05
    sta $0600,x               // Clear screen page $06
    sta $0700,x               // Clear screen page $07

    lda #$01                  // Load colour value $01, white
    sta $d800,x               // Initialise colour RAM page $d8
    sta $d900,x               // Initialise colour RAM page $d9
    sta $da00,x               // Initialise colour RAM page $da
    sta $db00,x               // Initialise colour RAM page $db

    inx                       // Move to the next position
    bne clear                 // Repeat until X wraps from $ff to $00

    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Routine that destroys X
// -----------------------------------------------------------------------------
//
// Input:
//
//   none
//
// Output:
//
//   none
//
// Destroys:
//
//   X
//   flags
//
// Preserves:
//
//   A
//   Y
//
// This routine deliberately changes X.
// It represents any routine that uses X internally and does not promise
// to preserve it.

destroys_x:
    ldx #$10                  // Destroy the caller's X value
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Routine that preserves X
// -----------------------------------------------------------------------------
//
// Input:
//
//   X - caller's X value
//
// Output:
//
//   none
//
// Destroys:
//
//   A
//   flags
//
// Preserves:
//
//   X
//   Y
//
// This routine saves X on the stack, uses X internally, then restores X
// before returning.
//
// It preserves X, but it uses A while doing so.
// Therefore it does not promise to preserve A.

preserves_x:
    txa                       // Copy X into A
    pha                       // Save X value on the stack

    ldx #$10                  // Use X internally

    pla                       // Restore saved X value into A
    tax                       // Copy A back to X

    rts                       // Return to the caller