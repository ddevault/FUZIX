	;
	;	For the Scrumpel this code assumes the kernel is at 0x00000
	;	on entry. Common and other high stuff is packed on the end
	;	of the image so if needed crt0 can adjust the other bank
	;	registers.
	;


	; 2013-12-18 William R Sowerbutts

        .module crt0
	.z180

        ; Ordering of segments for the linker.
        ; WRS: Note we list all our segments here, even though
        ; we don't use them all, because their ordering is set
        ; when they are first seen.
        .area _CODE
        .area _HOME     ; compiler stores __mullong etc in here if you use them
        .area _CODE2
        .area _CONST
        .area _INITIALIZED
        .area _DATA
        .area _BSEG
        .area _BSS
        .area _HEAP
        ; note that areas below here may be overwritten by the heap at runtime, so
        ; put initialisation stuff in here
        .area _BUFFERS     ; _BUFFERS grows to consume all before it (up to KERNTOP)
        .area _INITIALIZER
        .area _GSINIT
        .area _GSFINAL
        .area _DISCARD
        .area _COMMONMEM

        ; imported symbols
        .globl _fuzix_main
        .globl init_early
        .globl init_hardware
        .globl s__INITIALIZER
        .globl s__COMMONMEM
        .globl l__COMMONMEM
        .globl s__DISCARD
        .globl l__DISCARD
        .globl s__DATA
        .globl l__DATA
        .globl kstack_top

	.include "kernel.def"
        .include "../cpu-z180/z180.def"

	.globl outchar

        ; startup code
        .area _CODE
init:
        di
        ld sp, #kstack_top

	ld hl,#enter
	call debugstr

	xor a
	out0 (MMU_BBR),a
	out0 (MMU_CBR),a

        ; move the common memory where it belongs    
        ld hl, #s__DATA
        ld de, #s__COMMONMEM
        ld bc, #l__COMMONMEM
        ldir
        ; and the discard
        ld de, #s__DISCARD
        ld bc, #l__DISCARD
        ldir
        ; then zero the data area
        ld hl, #s__DATA
        ld de, #s__DATA + 1
        ld bc, #l__DATA - 1
        ld (hl), #0
        ldir

	ld hl,#movedok
	call debugstr


        ; Configure memory map
        call init_early

	ld hl,#early
	call debugstr

        ; Hardware setup
        call init_hardware

	ld hl,#inithw
	call debugstr

        ; Call the C main routine
        call _fuzix_main
    
        ; fuzix_main() shouldn't return, but if it does...
        di
stop:   halt
        jr stop

debug:
	push af
        ; wait for transmitter to be idle
ocloop: in0 a, (ASCI_STAT0)
        bit 1, a        ; and 0x02
        jr z, ocloop    ; loop while busy
        ; now output the char to serial port
	pop af
        out0 (ASCI_TDR0), a
        ret

debugstr:
	ld a,(hl)
	or a
	ret z
	call debug
	inc hl
	jr debugstr

movedok:
	.asciz 'Relocation and clear done'
inithw:
	.asciz 'Hardware initialized'
enter:
	.asciz 'Kernel image entered'
early:
	.asciz 'Early init complete'