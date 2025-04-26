; Program for the LCD to do MOSI SPI

.cpu 6502
.equ outputKIM, 0x1700 ; variable for address of SPI pins (where output will be sent from), bit 7 is MOSI, bit 6 is SS, bit 5 is SCLK
.equ outputSettings, 0x1701 ; variable for address of output settings, where we can set pins to inputs or outputs
.equ inputKIM, 0x1702 ; port B for input
.equ inputSettings, 0x1703

.equ output, 0x1000 ; variable for address of output (for byte_send)

.equ byte1, 0x1001 ; variable for address of display address byte
.equ byte2, 0x1002 ; variable for address of display digit byte 
.equ dataCount, 0x0040 ; variable for address of counter of current letter
.equ pageAddressByte1, 0x0041 ; stores the lower byte of address of a new page of content
.equ pageAddressByte2, 0x0042 ; higher byte of address
.equ answerAddressByte1, 0x0051 ; stores the lower byte of the address of the answer to the current question
.equ answerAddressByte2, 0x0052 ; stores the higher byte of the address
.equ userAnswer, 0x0050 ; stores the user's answer
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


    LDA #0x00
    STA pageAddressByte1
    STA answerAddressByte1
    LDA #0x20
    STA pageAddressByte2 ; default address at 0x2000
    LDA #0x90
    STA answerAddressByte2 ; default address for answers at 0x9000
    ; display the page
    send:
    LDA #0xFF
    STA dataCount ; initiallyzing the data count, by default it's -1 since we increment at the start of the loop
    JSR display_letter ; displays the page

    wait_for_input:
        LDA inputKIM
        CMP #0xFF
        BEQ wait_for_input ; keep looping until there's a button pressed
        wait_for_release:
        CMP #0xFF
        BNE wait_for_release ; need to release the button if pressed
    
    ; show option page that comes after the question page
    LDA #0xFF 
    STA dataCount
    JSR display_letter

    wait_for_answer:
        LDA inputKIM
        CMP #0xFF
        BEQ wait_for_input ; keep looping until there's a button pressed
        STA userAnswer ; saves user's answer the moment a button is pressed
        check_answer:
            LDY #0
            LDA (answerAddressByte1), Y ; load answer key
            CMP userAnswer
            BNE wrong_answer
            JSR show_answer_right
            JMP finish
            wrong_answer:
            JSR show_answer_wrong
        finish:
            JSR delay
            JSR delay
            JSR delay
            INC answerAddressByte1
            BNE no_carry
            INC answerAddressByte2
            no_carry:
            JMP send

    BRK

    # 0x1C

show_answer_right:
    LDA #'C'
    JSR send_a
    LDA #'O'
    JSR send_a
    LDA #'R'
    JSR send_a
    LDA #'R'
    JSR send_a  
    LDA #'E'
    JSR send_a 
    LDA #'C'
    JSR send_a
    LDA #'T'
    JSR send_a 
    RTS

show_answer_wrong:
    LDA #'I'
    JSR send_a
    LDA #'N'
    JSR send_a
    LDA #'C'
    JSR send_a
    LDA #'O'
    JSR send_a
    LDA #'R'
    JSR send_a
    LDA #'R'
    JSR send_a  
    LDA #'E'
    JSR send_a 
    LDA #'C'
    JSR send_a
    LDA #'T'
    JSR send_a 
    RTS

display_letter:
    LDY dataCount
    INY
    STY dataCount ; increment the count
    LDA (0x0041), Y
    BEQ end
    JSR send_a
    JMP display_letter

    end:
    ; update the two bytes storing the next address
    INY ; to the next address 
    LDA 0x41
    CLC
    ADC #0 ; clear carry
    TYA
    ADC 0x41
    STA 0x41

    LDA 0x42
    ADC #0 ; add carry
    STA 0x42
    RTS

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
    
    set_initial_input_state:
        LDA #0x00
        STA inputKIM
    
    make_output: ; make port A an output
        LDA #0xFF
        STA outputSettings
    
    make_input: ; make port B an input
        LDA #0x00
        STA inputSettings
    
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
.include "file.txt" ; file including text data for display

.org 0x9000
.include "answers.txt" ; file including answer keys
; put data or whatever here
; .include "file.txt" or something