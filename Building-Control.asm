DATA SEGMENT
ORG 03000H
    ; LCD & Keypad PPI
    PORTA EQU 0D0H
    PORTB EQU 0D2H
    PORTC EQU 0D4H
    COM_REG1 EQU 0D6H

    ; ADC PPI
    PORTD EQU 0D8H
    PORTE EQU 0DAH
    PORTF EQU 0DCH
    COM_REG2 EQU 0DEH

    ; Output PPI
    PORTG EQU 0E0H
    PORTH EQU 0E2H
    PORTI EQU 0E4H
    COM_REG3 EQU 0E6H

    ; Testing PPI
    PORTJ EQU 0F8H
    PORTK EQU 0FAH
    PORTL EQU 0FCH
    COM_REG4 EQU 0FEH

    ; 8259 PIC
    PIC1 EQU 0C6H
    PIC2 EQU 0C8H

    ; 8253 Timer
    PORT_T EQU 0C0H
    COM_REG_T EQU 0C6H

    ; Strings to be displayed on LCD
    MENU1_STR DB "Room 1 [1]", "$"
    MENU2_STR DB "Room 2 [2]", "$"
    MENU3_STR DB "Room 3 [3]", "$"
    MENU4_STR DB "All Rooms [4]", "$"
    ROOM1_STR DB "Room 1 ", "$"
    ROOM2_STR DB "Room 2 ", "$"
    ROOM3_STR DB "Room 3 ", "$"
    ROOMALL_STR DB "All Rooms", "$"
    TEMP_STR DB "Temperature: ", "$"
    PLACEHOLDER DB "PLACEHOLDER", "$"

    ; Data Variables
    ROOM1_FLAG DB 0
    ROOM2_FLAG DB 0
    ROOM3_FLAG DB 0
    ADC_CURR DB 0
    T0 DB "0", "$"
    T1 DB "1", "$"
    T2 DB "2", "$"
    T3 DB "3", "$"
    T4 DB "4", "$"
    T5 DB "5", "$"
    T6 DB "6", "$"
    T7 DB "7", "$"
    T8 DB "8", "$"
    T9 DB "9", "$"
    T10 DB "10", "$"
    T11 DB "11", "$"
    T12 DB "12", "$"
    T13 DB "13", "$"
    T14 DB "14", "$"
    T15 DB "15", "$"
    T16 DB "16", "$"
    T17 DB "17", "$"
    T18 DB "18", "$"
    T19 DB "19", "$"
    T20 DB "20", "$"
    T21 DB "21", "$"
    T22 DB "22", "$"
    T23 DB "23", "$"
    T24 DB "24", "$"
    T25 DB "25", "$"
    T26 DB "26", "$"
    T27 DB "27", "$"
    T28 DB "28", "$"
    T29 DB "29", "$"
    T30 DB "30", "$"
    T31 DB "31", "$"
    T32 DB "32", "$"
    T33 DB "33", "$"
    T34 DB "34", "$"
    T35 DB "35", "$"
    T36 DB "36", "$"
    T37 DB "37", "$"
    T38 DB "38", "$"
    T39 DB "39", "$"
    T40 DB "40", "$"
    T41 DB "41", "$"
    T42 DB "42", "$"
    T43 DB "43", "$"
    T44 DB "44", "$"
    T45 DB "45", "$"
    T46 DB "46", "$"
    T47 DB "47", "$"
    T48 DB "48", "$"
    T49 DB "49", "$"
    T50 DB "50", "$"
    T51 DB "51", "$"
    T52 DB "52", "$"
    T53 DB "53", "$"
    T54 DB "54", "$"
    T55 DB "55", "$"
    T56 DB "56", "$"
    T57 DB "57", "$"
    T58 DB "58", "$"
    T59 DB "59", "$"
    T60 DB "60", "$"
DATA ENDS


STK SEGMENT STACK
   BOS DW 64d DUP (?)
   TOS LABEL WORD
STK ENDS


CODE SEGMENT PUBLIC 'CODE'
    ASSUME CS:CODE, DS:DATA, SS:STK
    ORG 08000H

START:
    ; configure PPIs
    MOV DX, COM_REG1
    MOV AL, 10001001B
    OUT DX, AL
    MOV DX, COM_REG2
    MOV AL, 10001001B
    OUT DX, AL
    MOV DX, COM_REG4
    MOV AL, 10001001B
    OUT DX, AL

    INIT:
    MOV AL, 000H        ; just output 00H to PPI
    OUT PORTJ, AL
    CALL INIT_LCD
    CALL SHOW_MENU
    CALL MENU_CHECK_DAVBL
    JMP ENDLESS

    ; MODULE: display menu
    SHOW_MENU:
        MOV AL, 085H        ; set cursor position
        LEA SI, MENU1_STR   ; move strng to display
        CALL DISPLAY_STR    ; instruct LCD and display string from SI

        MOV AL, 0C5H
        LEA SI, MENU2_STR
        CALL DISPLAY_STR

        MOV AL, 099H
        LEA SI, MENU3_STR
        CALL DISPLAY_STR

        MOV AL, 0D8H
        LEA SI, MENU4_STR
        CALL DISPLAY_STR
    RET

    ; MODULE: Check DAVBL for menu
    MENU_CHECK_DAVBL:
        CALL READ_ADC
        MOV AL, ADC_CURR
        CALL ADC_DATA_CONVERTER
        MOV AL, 0A1H
        CALL DISPLAY_STR

        MOV DX, PORTC
        IN AL, DX; read PORTC
        TEST AL, 10H ; check if DAVBL is high
        JZ MENU_CHECK_DAVBL ; if low then check again
        IN AL, DX ; read 4-bit keypad data
        AND AL, 0FH ; mask upper nibble
        CMP AL, 00H ; check if key pressed is 1 (00H)
        JE ROOM1 ; go to room 1 menu
        CMP AL, 01H ; check if key pressed is 2 (01H)
        JE ROOM2 ; go to room 2 menu
        CMP AL, 02H ; check if key pressed is 3 (02H)
        JE ROOM3 ; go to room 3 menu
        CMP AL, 04H ; check if key pressed is 3 (02H)
        JE ROOMALL ; go to room all menu
        CMP AL, 0EH ; check if key pressed is # (0EH)
        JE BACK ; go back to menu
        CALL DELAY_1MS
        JMP MENU_CHECK_DAVBL

    ; MODULE: Rooms menu
    ROOM1:
        ; MOV ROOM1_FLAG, 1
        MOV DX, PORTE
        MOV AL, 01H
        OUT DX, AL
        CALL INIT_LCD
        MOV AL, 080H
        LEA SI, ROOM1_STR
        CALL DISPLAY_STR
        MOV AL, 094H
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    ROOM2:
        ; MOV ROOM2_FLAG, 1
        MOV DX, PORTE
        MOV AL, 02H
        OUT DX, AL
        CALL INIT_LCD
        MOV AL, 080H
        LEA SI, ROOM2_STR
        CALL DISPLAY_STR
        MOV AL, 094H
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    ROOM3:
        ; MOV ROOM3_FLAG, 1
        MOV DX, PORTE
        MOV AL, 04H
        OUT DX, AL
        CALL INIT_LCD
        MOV AL, 080H
        LEA SI, ROOM3_STR
        CALL DISPLAY_STR
        MOV AL, 094H
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    ROOMALL:
        CALL INIT_LCD
        MOV AL, 080H
        LEA SI, ROOMALL_STR
        CALL DISPLAY_STR
        MOV AL, 094H
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    BACK:
        MOV DX, PORTE
        MOV AL, 00H
        OUT DX, AL
        JMP INIT

        CONT:
            CALL DELAY_1MS
            JMP MENU_CHECK_DAVBL

    ; MODULE: fetch data from temperature sensor using ADC
    ; ALE ADDC ADDB ADDA
    ;  1   0    0    0    =  TEMPSEN_1
    ;  1   0    0    1    =  TEMPSEN_2
    ;  1   0    1    0    =  TEMPSEN_3
    READ_ADC:
        ; MOV DX, PORTE       ; select address decoder port
        ; CMP ROOM1_FLAG, 1
        ; JE AT_ROOM1
        ; CMP ROOM2_FLAG, 1
        ; JE AT_ROOM2
        ; CMP ROOM3_FLAG, 1
        ; JE AT_ROOM3
        ; MOV AL, 00H
        CONT_ADC:
        ; OUT DX, AL
        MOV DX, PORTD       ; select ADC out port
        IN AL, DX           ; store digital data to AL
        MOV ADC_CURR, AL
    RET
        AT_ROOM1:
            MOV AL, 01H   ; select analog channel
            JMP CONT_ADC
        AT_ROOM2:
            MOV AL, 02H
            JMP CONT_ADC
        AT_ROOM3:
            MOV AL, 03H
            JMP CONT_ADC


    TEMP_SEN_1:
        CALL ADC_DATA_CONVERTER
        MOV AL, 0A1H
        CALL DISPLAY_STR
    RET
    TEMP_SEN_2:
        MOV DX, PORTE
        MOV AL, 00001001B
        OUT DX, AL
        MOV DX, PORTD
        IN AL, DX
        MOV DX, PORTJ
        OUT DX, AL
    RET
    TEMP_SEN_3:
        MOV DX, PORTE
        MOV AL, 00001010B
        OUT DX, AL
        MOV DX, PORTD
        IN AL, DX
        MOV DX, PORTJ
        OUT DX, AL
    RET

    ; MODULE: Endless loop
    ENDLESS:
        JMP ENDLESS

    INST_CTRL:
        PUSH AX ; preserve value of AL
        MOV DX, PORTA ; set port of LCD data bus (PORTA)
        OUT DX, AL ; write data in AL to PORTA
        MOV DX, PORTB ; set port of LCD control lines (PORTB)
        MOV AL, 02H ; E=1, RS=0 (access instruction reg)
        OUT DX, AL ; write data in AL to PORTB
        CALL DELAY_1MS ; delay for 1 ms
        MOV DX, PORTB ; set port of LCD control lines (PORTB)
        MOV AL, 00H ; E=0, RS=0
        OUT DX, AL ; write data in AL to PORTB
        POP AX ; restore value of AL
    RET

    DATA_CTRL:
        PUSH AX ; preserve value of AL
        MOV DX, PORTA ; set port of LCD data bus (PORTA)
        OUT DX, AL ; write data in AL to PORTA
        MOV DX, PORTB ; set port of LCD control lines (PORTB)
        MOV AL, 03H ; E=1, RS=1 (access data register)
        OUT DX, AL ; write data in AL to PORTB
        CALL DELAY_1MS ; delay for 1 ms
        MOV DX, PORTB ; set port of LCD control lines (PORTB)
        MOV AL, 01H ; E=0, RS=1
        OUT DX, AL ; write data in AL to PORTB
        POP AX ; restore value of AL
    RET

    INIT_LCD:
        MOV AL, 38H ; 8-bit interface, dual-line display
        CALL INST_CTRL ; write instruction to LCD
        MOV AL, 08H ; display off, cursor off, blink off
        CALL INST_CTRL ; write instruction to LCD
        MOV AL, 01H ; clear display
        CALL INST_CTRL ; write instruction to LCD
        MOV AL, 06H ; increment cursor, display shift off
        CALL INST_CTRL ; write instruction to LCD
        MOV AL, 0CH ; display on, cursor off, blink off
        CALL INST_CTRL ; write instruction to LCD
    RET

    ; MODULE: Displays a string from SI
    DISPLAY_STR: CALL INST_CTRL
    DISP:
        MOV AL, [SI]
        CMP AL, '$'
        JE EXIT
        CALL DATA_CTRL
        INC SI
        JMP DISP
    RET

    ; MODULE: Convert the digital data from ADC to a string format
    ADC_DATA_CONVERTER:
        CMP AL, 000H
        JE TEMP_0
        CMP AL, 002H
        JE TEMP_1
        CMP AL, 004H
        JE TEMP_2
        CMP AL, 005H
        JE TEMP_3
        CMP AL, 007H
        JE TEMP_4
        CMP AL, 009H
        JE TEMP_5
        CMP AL, 00AH
        JE TEMP_6
        CMP AL, 00CH
        JE TEMP_7
        CMP AL, 00EH
        JE TEMP_8
        CMP AL, 010H
        JE TEMP_9
        CMP AL, 011H
        JE TEMP_10

        CMP AL, 013H
        JE TEMP_11
        CMP AL, 015H
        JE TEMP_12
        CMP AL, 016H
        JE TEMP_13
        CMP AL, 018H
        JE TEMP_14
        CMP AL, 01AH
        JE TEMP_15
        CMP AL, 01BH
        JE TEMP_16
        CMP AL, 01DH
        JE TEMP_17
        CMP AL, 01FH
        JE TEMP_18
        CMP AL, 021H
        JE TEMP_19
        CMP AL, 022H
        JE TEMP_20

        CMP AL, 024H
        JE TEMP_21
        CMP AL, 026H
        JE TEMP_22
        CMP AL, 027H
        JE TEMP_23
        CMP AL, 029H
        JE TEMP_24
        CMP AL, 02BH
        JE TEMP_25
        CMP AL, 02CH
        JE TEMP_26
        CMP AL, 02EH
        JE TEMP_27
        CMP AL, 030H
        JE TEMP_28
        CMP AL, 032H
        JE TEMP_29
    RET

        TEMP_0:
            LEA SI, T0
        RET
        TEMP_1:
            LEA SI, T1
        RET
        TEMP_2:
            LEA SI, T2
        RET
        TEMP_3:
            LEA SI, T3
        RET
        TEMP_4:
            LEA SI, T4
        RET
        TEMP_5:
            LEA SI, T5
        RET
        TEMP_6:
            LEA SI, T6
        RET
        TEMP_7:
            LEA SI, T7
        RET
        TEMP_8:
            LEA SI, T8
        RET
        TEMP_9:
            LEA SI, T9
        RET
        TEMP_10:
            LEA SI, T10
        RET
        TEMP_11:
            LEA SI, T11
        RET
        TEMP_12:
            LEA SI, T12
        RET
        TEMP_13:
            LEA SI, T13
        RET
        TEMP_14:
            LEA SI, T14
        RET
        TEMP_15:
            LEA SI, T15
        RET
        TEMP_16:
            LEA SI, T16
        RET
        TEMP_17:
            LEA SI, T17
        RET
        TEMP_18:
            LEA SI, T18
        RET
        TEMP_19:
            LEA SI, T19
        RET
        TEMP_20:
            LEA SI, T20
        RET
        TEMP_21:
            LEA SI, T21
        RET
        TEMP_22:
            LEA SI, T22
        RET
        TEMP_23:
            LEA SI, T23
        RET
        TEMP_24:
            LEA SI, T24
        RET
        TEMP_25:
            LEA SI, T25
        RET
        TEMP_26:
            LEA SI, T26
        RET
        TEMP_27:
            LEA SI, T27
        RET
        TEMP_28:
            LEA SI, T28
        RET
        TEMP_29:
            LEA SI, T29
        RET



    DELAY_1MS:  MOV BX, 02CAH
    L1:
        DEC BX
        NOP
        JNZ L1
        RET
    RET

    EXIT:
        RET
CODE ENDS
END START
