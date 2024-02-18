.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 0               ; 1x  8KB CHR data
  .byte $00, $00        ; mapper 0, vertical mirroring

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
PPUSCROLL = $2005
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
  
  lda #$00
  sta PPUCTRL   ; disable NMIs
  sta PPUMASK   ; disable rendering

  lda #$00
  sta PPUSCROLL ; X scroll position
  lda #$00
  sta PPUSCROLL ; Y scroll position

  stx $4010 	; disable DMC IRQs

@load_tiles:	
  ; Init PPUADDR to pattern table start
  lda #$00  ; High byte of $0000
  sta PPUADDR ; Set high byte of address
  lda #$00  ; Low byte of $0000
  sta PPUADDR ; Set low byte of address
  
ldx #$00
loop:
  lda tiles, x 	; Load each tile
  sta PPUDATA
  inx
  cpx #$a0
  bne loop

@init_bg:
  ; Load tiles to nametable to write full name
  ; Set PPUADDR to nametable start
  lda PPUSTATUS
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  
  ; Loop to load full_name tile indices
  ldx #$00
  write_name:
  lda full_name, x
  sta PPUDATA
  inx
  cpx #$0c
  bne write_name

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
  lda #%10000000 ; Enable NMI and background rendering.
  sta PPUCTRL
  lda #%00011110 ; Enable background and sprite rendering in PPUMASK.
  sta PPUMASK

forever:
  jmp forever

nmi:
  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003
  rti

palettes:
  ; Background Palette
  .byte $0f, $02, $03, $04
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $02, $00, $03
  .byte $0f, $04, $00, $05
  .byte $0f, $06, $00, $07
  .byte $0f, $08, $00, $09

tiles:
  ; empty tile
  .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
  .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

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

full_name:
  .byte $01, $02, $03, $04 ; Joel
  .byte $05, $04, $06, $07, $08, $07, $09, $02
