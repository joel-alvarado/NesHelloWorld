.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  ldx #$00
@loop:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne @loop

enable_rendering:
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00010000	; Enable Sprites
  sta $2001

forever:
  jmp forever

nmi:
  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003
@loop:	lda first_name, x 	; Load the hello message into SPR-RAM
  sta $2004
  inx
  cpx #$30
  bne @loop
  rti

first_name:
  ; .byte $00, $00, $00, $00 	; Why do I need these here?
  ; .byte $00, $00, $00, $00

  .byte $6c, $00, $00, $6c  ; y=0x6c(108), S=$00, P=$00, x=0x76(108) J
  .byte $6c, $01, $00, $72  ; y=0x6c(108), S=$01, P=$00, x=0x74(116) o
  .byte $6c, $02, $01, $78  ; y=0x6c(108), S=$02, P=$00, x=0x7c(124) e
  .byte $6c, $03, $01, $7b  ; y=0x6c(108), S=$03, P=$00, x=0x84(132) l

last_name:
  .byte $78, $04, $02, $6c  ; y=0x6c(108), S=$04, P=$00, x=0x8c(140) A
  .byte $78, $03, $02, $6f  ; y=0x6c(108), S=$03, P=$00, x=0x84(132) l
  .byte $78, $05, $03, $74  ; y=0x6c(108), S=$03, P=$00, x=0x84(132) v
  .byte $78, $06, $03, $7a  ; y=0x6c(108), S=$03, P=$00, x=0x84(132) a
  .byte $78, $07, $01, $80  ; y=0x6c(108), S=$03, P=$00, x=0x84(132) r
  .byte $78, $06, $02, $85  ; y=0x6c(108), S=$03, P=$00, x=0x84(132) a
  .byte $78, $08, $00, $8b  ; y=0x6c(108), S=$03, P=$00, x=0x84(132) d
  .byte $78, $01, $00, $91  ; y=0x6c(108), S=$01, P=$00, x=0x74(116) o



palettes:
  ; Background Palette
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $02, $00, $03
  .byte $0f, $04, $00, $05
  .byte $0f, $06, $00, $07
  .byte $0f, $08, $00, $09

; Character memory
.segment "CHARS"
  ; J
  .byte %00000001
  .byte %00000001
  .byte %00000001
  .byte %00000001
  .byte %00000001
  .byte %00000001
  .byte %00010001
  .byte %00001110
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; o
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00001110
  .byte %00010001
  .byte %00010001
  .byte %00010001
  .byte %00001110

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00001110
  .byte %00010001
  .byte %00010001
  .byte %00010001
  .byte %00001110

  ; e
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00001110
  .byte %00010001
  .byte %00011111
  .byte %00010000
  .byte %00001111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; l
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000001

  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000010
  .byte %00000001

  ; A
  .byte %00001110
  .byte %00010001
  .byte %00011111
  .byte %00010001
  .byte %00010001
  .byte %00010001
  .byte %00010001
  .byte %00010001
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; v
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00010001
  .byte %00010001
  .byte %00010001
  .byte %00001010
  .byte %00000100

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00010001
  .byte %00010001
  .byte %00010001
  .byte %00001010
  .byte %00000100

  ; a
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00001110
  .byte %00000001
  .byte %00001111
  .byte %00010001
  .byte %00001111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; r
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00010110
  .byte %00011001
  .byte %00010000
  .byte %00010000
  .byte %00010000
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; d
  .byte %00000001
  .byte %00000001
  .byte %00000001
  .byte %00001101
  .byte %00010011
  .byte %00010001
  .byte %00010001
  .byte %00001111
  .byte $00, $00, $00, $00, $00, $00, $00, $00