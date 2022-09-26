	.include "cpm65.inc"
	.include "zif.inc"
	.include "xfcb.inc"

	.import xfcb_writesequential
	.import xfcb_readsequential
	.import xfcb_make
	.import xfcb_open
	.import xfcb_close

	.zeropage

address: .res 3
index:	 .res 1

	.code
	CPM65_COM_HEADER

.scope
	; Did we get a parameter?

	lda FCB+xfcb::f1
	cmp #' '
	beq syntax_error

	; Try and open the file.

	lda #<FCB
	ldx #>FCB
	jsr xfcb_open
	bcs cannot_open

	lda #<output_fcb
	ldx #>output_fcb
	jsr xfcb_open
	zif_cs
		lda #<output_fcb
		ldx #>output_fcb
		jsr xfcb_make
		bcs cannot_open
	zendif

	; Read all the blocks in the file.

	zrepeat
		lda #'.'
		jsr bdos_CONOUT

		lda #<buffer
		ldx #>buffer
		jsr bdos_SETDMA

		lda #<FCB
		ldx #>FCB
		jsr xfcb_readsequential
		zbreakif_cs

		lda #<output_fcb
		ldx #>output_fcb
		jsr xfcb_writesequential
	zuntil_cs

	; Close the files.

	lda #<FCB
	ldx #>FCB
	jsr xfcb_close

	lda #<output_fcb
	ldx #>output_fcb
	jsr xfcb_close

	rts
.endscope

.data
output_fcb:
	.byte 0
	.byte "OUTPUT  DAT"
	.byte 0, 0, 0, 0
	.res 16
	.byte 0, 0, 0, 0
	.byte 0				; user area

.bss
buffer:
	.res 128
.code

.proc syntax_error
	lda #<msg
	ldx #>msg
	jmp bdos_WRITESTRING
msg:
	.byte "Syntax error", 13, 10, 0
.endproc

.proc cannot_open
	lda #<msg
	ldx #>msg
	jmp bdos_WRITESTRING
msg:
	.byte "Cannot open file", 13, 10, 0
.endproc

newline:
	lda #13
	jsr bdos_CONOUT
	lda #10
	; fall through
bdos_CONOUT:
	ldy #bdos::console_output
	jmp BDOS

bdos_SETDMA:
	ldy #bdos::set_dma_address
	jmp BDOS

bdos_WRITESTRING:
	ldy #bdos::write_string
	jmp BDOS

