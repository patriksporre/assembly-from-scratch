// Assembly from Scratch
// Platform: Commodore 64
// Lesson 17: Measuring raster time with the border
//
// This lesson uses the C64 border as a simple visual profiler.
//
// Lesson 16 changed the border colour at fixed raster positions.
//
// This lesson turns the border colour on before a piece of work,
// and turns it off after the work is finished.
//
// The height of the coloured border area shows roughly how much raster time
// the work consumed.
//
// The timing display is only shown while SPACE is held down.
//
// This lesson also disables normal IRQ interrupts with sei.
// That makes the timing display cleaner because the normal KERNAL IRQ
// no longer interrupts our measurement loop.
//
// This is a common old-school technique.
// It makes performance visible.

// -----------------------------------------------------------------------------
// BASIC loader
// -----------------------------------------------------------------------------

* = $0801

    .word basic_next_line
    .word 10
    .byte $9e
    .text "2061"
    .byte 0

basic_next_line:
    .word 0

// -----------------------------------------------------------------------------
// Machine code
// -----------------------------------------------------------------------------

* = $080d

start:
    sei                       // Disable normal IRQ interrupts for cleaner timing

    lda #$00
    sta $d020
    sta $d021

main_loop:
    jsr wait_next_frame

    lda #$00
    sta $d020

    jsr is_space_pressed
    sta show_timing

    lda show_timing
    beq skip_border_on

    lda #$06
    sta $d020

skip_border_on:
    jsr do_work

    lda #$00
    sta $d020

    jmp main_loop

// -----------------------------------------------------------------------------
// Wait next frame subroutine
// -----------------------------------------------------------------------------

wait_next_frame:
wait_high_raster:
    lda $d011
    bpl wait_high_raster

wait_new_frame:
    lda $d011
    bmi wait_new_frame

    rts

// -----------------------------------------------------------------------------
// Is space pressed subroutine
// -----------------------------------------------------------------------------

is_space_pressed:
    lda #%01111111
    sta $dc00

    lda $dc01
    and #%00010000
    beq space_is_pressed

space_not_pressed:
    lda #0
    rts

space_is_pressed:
    lda #1
    rts

// -----------------------------------------------------------------------------
// Do work subroutine
// -----------------------------------------------------------------------------

do_work:
    ldx #$02

work_outer:
    ldy #$ff

work_inner:
    dey
    bne work_inner

    dex
    bne work_outer

    rts

// -----------------------------------------------------------------------------
// State data
// -----------------------------------------------------------------------------

show_timing:
    .byte 0