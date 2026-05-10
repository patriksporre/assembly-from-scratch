// Assembly from Scratch
// Platform: Commodore 64
// Lesson 09: Text subroutine
//
// This lesson introduces subroutines and zero-page pointers.
//
// In the previous lesson, one loop copied one zero-terminated message
// to one fixed screen position.
//
// In this lesson, we write one reusable print routine.
//
// The routine can print different messages at different screen positions.
//
// To do that, it uses two zero-page pointers:
//
//   message_ptr - where the message starts
//   screen_ptr  - where the text should appear
//
// The print routine reads a zero-terminated message and copies it to the screen.

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
// Zero-page pointers
// -----------------------------------------------------------------------------
//
// These constants name zero-page addresses used as two-byte pointers.
//
// message_ptr uses $fb-$fc.
// screen_ptr uses $fd-$fe.
//
// The indirect indexed addressing mode:
//
//   (pointer),y
//
// requires the pointer to live in zero page.

.const message_ptr = $fb
.const screen_ptr  = $fd

// -----------------------------------------------------------------------------
// Machine code
// -----------------------------------------------------------------------------

* = $080d

.encoding "screencode_upper"  // Convert .text strings to C64 uppercase screen codes

start:
    lda #$06                  // Load colour value $06, blue
    sta $d020                 // Store it in the VIC-II border colour register
    sta $d021                 // Store it in the VIC-II background colour register

// -----------------------------------------------------------------------------
// Pointer setup
// -----------------------------------------------------------------------------
//
// A C64 address is 16 bits, so a pointer needs two bytes.
//
// The 6510 stores 16-bit addresses in little-endian order:
//
//   low byte first
//   high byte second
//
// KickAssembler's < and > operators extract those bytes:
//
//   <address = low byte
//   >address = high byte
//
// The C64 screen is 40 columns wide:
//
//   $0400 = row 0, column 0
//   $0428 = row 1, column 0 ($0400 + 40)
//   $0450 = row 2, column 0 ($0400 + 80)

    lda #<message_assembly    // Load low byte of message_assembly address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message_assembly    // Load high byte of message_assembly address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0400               // Load low byte of screen address $0400
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0400               // Load high byte of screen address $0400
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    jsr print                 // Print message_assembly at $0400

    lda #<message_from        // Load low byte of message_from address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message_from        // Load high byte of message_from address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0428               // Load low byte of screen address $0428
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0428               // Load high byte of screen address $0428
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    jsr print                 // Print message_from at $0428

    lda #<message_scratch     // Load low byte of message_scratch address
    sta message_ptr           // Store it in the low byte of message_ptr
    lda #>message_scratch     // Load high byte of message_scratch address
    sta message_ptr + 1       // Store it in the high byte of message_ptr

    lda #<$0450               // Load low byte of screen address $0450
    sta screen_ptr            // Store it in the low byte of screen_ptr
    lda #>$0450               // Load high byte of screen address $0450
    sta screen_ptr + 1        // Store it in the high byte of screen_ptr

    jsr print                 // Print message_scratch at $0450

    rts                       // Return to BASIC

// -----------------------------------------------------------------------------
// Print subroutine
// -----------------------------------------------------------------------------
//
// Prints a zero-terminated message to screen memory.
//
// Input:
//
//   message_ptr - address of the zero-terminated message
//   screen_ptr  - address where the message should appear
//
// Uses:
//
//   A - current character
//   Y - offset into the message and screen position

print:
    ldy #$00                  // Start Y at zero

copy:
    lda (message_ptr),y       // Load one byte from message_ptr + Y
    beq done                  // If the byte is zero, the message is finished

    sta (screen_ptr),y        // Store the byte at screen_ptr + Y

    iny                       // Move to the next character
    jmp copy                  // Continue copying

done:
    rts                       // Return to the caller

// -----------------------------------------------------------------------------
// Message data
// -----------------------------------------------------------------------------

message_assembly:
    .text "ASSEMBLY"
    .byte 0

message_from:
    .text "FROM"
    .byte 0

message_scratch:
    .text "SCRATCH"
    .byte 0