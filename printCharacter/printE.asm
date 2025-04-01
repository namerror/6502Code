    .org 0x0200

    CLD ;clear decimal mode to prevent error
    LDA #0x45 ;ASCII hex for character "E"
    JSR 0x1EA0 ;OUTCH
    BRK