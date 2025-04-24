; Program for outline of code to do MOSI SPI

.cpu 6502
.equ outputKIM, 0x1700 ; variable for address of SPI pins (where output will be sent from), bit 7 is MOSI, bit 6 is SS, bit 5 is SCLK
.equ outputSettings, 0x1701 ; variable for address of output settings, where we can set pins to inputs or outputs

.equ output, 0x1000 ; variable for address of output (for byte_send)

.equ byte1, 0x1001 ; variable for address of display address byte
.equ byte2, 0x1002 ; variable for address of display digit byte 

.org 0x0200

main:
    ; example code to display a HELLO
    ; data sheet: 

    JSR setup

    ; setup
    set_up:

        ; send data to turn on display
        LDA #0xFE
        JSR send_a
        LDA #0x41
        JSR send_a

        ; send data to clear screen
        LDA #0xFE
        JSR send_a
        LDA #0x51
        JSR send_a

        JSR delay


    ; send data for HELLO
    send:

    LDA #0x48
    JSR send_a

    JSR delay

    LDA #0x65
    JSR send_a

    JSR delay

    LDA #0x6C
    JSR send_a

    JSR delay

    LDA #0x6C
    JSR send_a

    JSR delay

    LDA #0x6F
    JSR send_a

    JSR delay
    
    LDA #0xFE
    JSR send_a
    
    JSR delay

    LDA #0x4B
    JSR send_a

    LDA #0xFE
    JSR send_a

    LDA #0x56
    JSR send_a

    BRK

    # 0x1C

    



byte_send: ; subroutine to send 8 bits (bit 7 is data, bit 6 is CS/SS, bit 5 is CLK)

    set_cs_low:
        LDA outputKIM
        AND #0b10111111  ; Pull SS (bit 6) low
        STA outputKIM

    set_clk_high: ; set the clock low before getting data in pin 7
        LDA outputKIM
        ORA #0b00100000   ; Pull CLK (bit 5) high
        STA outputKIM
    
    set_counter: ; counter to see how many bits have been sent of byte
        LDX #0x08
        
    send_output: ; send byte of data
        
        ; store output bit in outputKIM bit 7
        LDA output ; load output into accumulator
        AND #0b10000000 ; AND output so only last bit is recognized
        ORA outputKIM ; OR output to what's in 0x1700, nothing is changed except last bit
        STA outputKIM ; store result in KIM output bit
        
        ASL output ; arithmetic shift left of output1 to move next output1 bit to bit 0
    
    clk_cycle: ; simulate a clock cycle that occurs
               ; data has to be stable before clock rising edge
        
        LDA outputKIM ;load outputKIM into memory
        EOR #0b00100000 ; Invert SCLK (bit 5)
        STA outputKIM ; Store into outputKIM
        
        LDA outputKIM ; load outputKIM
        EOR #0b00100000 ; Invert SCLK (bit 5)
        STA outputKIM ; Store into outputKIM
        
        LDA outputKIM ; set final digit of outputKIM to 0 so it is modified correctly on next edge
        AND #0b01111111
        STA outputKIM
        
        DEX ; decrement number of bits remaining to be sent
        
        BNE send_output ; jump to send_output for next bit

    set_cs_high:
        LDA outputKIM
        ORA #0b01000000  ; Pull SS (bit 6) high
        STA outputKIM
        
    RTS ; end subroutine

setup: ; setup subroutine

    clear_decimal_mode:
        CLD
    
    set_initial_output_state: ; set outputKIM to 0x00
        LDA #0x00
        STA outputKIM
    
    make_output: ; make port A an output
        LDA #0xFF
        STA outputSettings
    
    set_low: ; Pull SS low and CLK pin high by ANDing with outputKIM and storing it back
            LDA outputKIM
            ORA #0b00100000  ; Pull CLK (bit 5) high
            AND #0b10111111  ; Pull SS (bit 6) low
            STA outputKIM
            
    RTS

send_a:
    STA output
    JSR byte_send
    RTS

delay: ; delay subroutine

    LDX #0xFF ; Load X with outer loop count (e.g., 255)
    outer_loop:
    
            LDA #0xFF
            inner_loop:
                SBC #0x01
                BNE inner_loop
            
        DEX
        BNE outer_loop
        
    RTS ; end subroutine


.org 0x2000 ; 

; put data or whatever here
; .include "file.txt" or something