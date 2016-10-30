org 100h
jmp start
%macro DESCRIPTOR_GDT 3					;1:BASE,2:LIMIT,3:ATTR
	; dw  %2&0000ffffh
	; dw  %1&0000ffffh
	; db  (%1>>16)&00ffh
	; db  %3&00ffh
	; db  ((%2>>8)&0xf00 )|(%3&0xf0ff)    ;((%2>>16)&000fh)+((%3>>8)<<4)
	; db  (%1>>24)&0ffh
	dw	%2 & 0FFFFh				; 段界限1
	dw	%1 & 0FFFFh				; 段基址1
	db	(%1 >> 16) & 0FFh			; 段基址2
	dw	((%2 >> 8) & 0F00h) | (%3 & 0F0FFh)	; 属性1 + 段界限2 + 属性2
	db	(%1 >> 24) & 0FFh			; 段基址3
%endmacro
ATTR_DES_32      EQU 4000h
ATTR_DES_onlyrun EQU 98h
ATTR_DES_wr		 EQU 92h

[SECTION GDT]
	GDT0         DESCRIPTOR_GDT 0,         0,          0 
	GDT_CODE32   DESCRIPTOR_GDT 0,         0xffff,     ATTR_DES_32+ATTR_DES_onlyrun
	GDT_VEDIO_G  DESCRIPTOR_GDT 0xa0000,   0xffff,     ATTR_DES_32+ATTR_DES_wr
	GDT_VEDIO_T  DESCRIPTOR_GDT 0xb8000,   0x7fff,     ATTR_DES_32+ATTR_DES_wr

	GDTR dw $-GDT0-1 
		 dd 0

	SELECTOR_CODE32  EQU 8
	SELECTOR_VEDIO_G EQU 16
	SELECTOR_VEDIO_T EQU 24


[BITS 16]
[SECTION text16]
start:
	mov ax,cs
	mov ss,ax
	mov ds,ax
	mov sp,100h

	shl eax,4
	add eax,code32
	mov word[GDT_CODE32+2],ax
	shr eax,16
	mov byte[GDT_CODE32+4],al
	mov byte[GDT_CODE32+7],ah

	mov ax,ds
	shl eax,4
	add eax,GDT0
	mov dword[GDTR+2],eax

	mov al,0x13
	mov ah,0x00
	int 0x10

	lgdt[GDTR]

	cli
    
    in al,92h
    or al,00000010b
    out 92h,al

    mov eax,cr0
    or  eax,1
    mov cr0,eax

    jmp dword SELECTOR_CODE32:0



[BITS 32]
[SECTION text32]

;extern _draw
;global _start

code32:
	
		mov ax,SELECTOR_VEDIO_G
		mov gs,ax
		mov edi,0
		
		l:
		cmp edi,0xffff
		jle l1
		jmp fin
		l1:
		mov eax,edi
		and eax,0x0f
		mov byte[gs:edi],al
		inc edi
		jmp l
	fin:
	  hlt
	  jmp fin
	

