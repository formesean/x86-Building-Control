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

    ; Fans PPI
    PORTJ EQU 0F0H
    PORTK EQU 0F2H
    PORTL EQU 0F4H
    COM_REG4 EQU 0F6H
    PORTM EQU 0F8H
    PORTN EQU 0FAH
    PORTO EQU 0FCH
    COM_REG5 EQU 0FEH

    ; 8259 PIC
    PIC1 EQU 0C8H
    PIC2 EQU 0CAH

    ; ; 8253 Timer
    ; PORT_T EQU 0C0H
    ; COM_REG_T EQU 0C6H

    ; Strings to be displayed on LCD
    MENU1_STR DB "Room 1 [1]", "$"
    MENU2_STR DB "Room 2 [2]", "$"
    MENU3_STR DB "Room 3 [3]", "$"
    MENU4_STR DB "All Rooms [4]", "$"
    ROOM1_STR DB "Room 1 ", "$"
    ROOM2_STR DB "Room 2 ", "$"
    ROOM3_STR DB "Room 3 ", "$"
    ROOM1_FAN1_STR DB "Fan 1: ", "$"
    ROOM1_FAN2_STR DB "Fan 2: ", "$"
    ROOM2_FAN1_STR DB "Fan 1: ", "$"
    ROOM2_FAN2_STR DB "Fan 2: ", "$"
    ROOM3_FAN1_STR DB "Fan 1: ", "$"
    ROOM3_FAN2_STR DB "Fan 2: ", "$"
    ROOMALL_STR DB "All Rooms", "$"
    FAN_ON_STR DB "[ON] ", "$"
    FAN_OFF_STR DB "[OFF]", "$"
    TEMP_STR DB "Temperature: ", "$"
    PLACEHOLDER DB "PLACEHOLDER", "$"

    ; Data Variables
    AT_ROOM_FLAG DB 0
    AT_ROOM1_FLAG DB 0
    AT_ROOM2_FLAG DB 0
    AT_ROOM3_FLAG DB 0
    ADC_CURR DB 0
    FAN_STATE DB 00000000B
    FAN1_FLAG DB 0
    FAN2_FLAG DB 0
    FAN3_FLAG DB 0
    FAN4_FLAG DB 0
    FAN5_FLAG DB 0
    FAN6_FLAG DB 0
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
    MOV AL, 10000000B
    OUT DX, AL
    MOV DX, COM_REG3
    MOV AL, 10000000B
    OUT DX, AL
    MOV DX, COM_REG4
    MOV AL, 10000000B
    OUT DX, AL
    MOV DX, COM_REG5
    MOV AL, 10000000B
    OUT DX, AL

    INIT:
    ; MOV DX, PORTF
    ; MOV AL, 01H
    ; OUT DX, AL
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
        ; MOV DX, PORTH
        ; MOV AL, 04H
        ; OUT DX, AL
        CMP AT_ROOM_FLAG, 1
        JNE CONT_MENU
        CALL READ_ADC
        CALL ADC_DATA_CONVERTER
        MOV AL, 0E1H
        CALL DISPLAY_STR

        CONT_MENU:
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
        CMP AL, 08H ; check if key pressed is 7 (08H)
        JE FAN1 ; go to FIRST_FAN module
        CMP AL, 0AH ; check if key pressed is 9 (0AH)
        JE SECOND_FAN ; go to SECOND_FAN module
        CMP AL, 0EH ; check if key pressed is # (0EH)
        JE BACK ; go back to menu
        CALL DELAY_1MS
        JMP MENU_CHECK_DAVBL


    ; MODULE: Rooms menu
    ROOM1:
        MOV AT_ROOM_FLAG, 1
        MOV AT_ROOM1_FLAG, 1
        MOV AT_ROOM2_FLAG, 0
        MOV AT_ROOM3_FLAG, 0
        MOV DX, PORTE
        MOV AL, 01H
        OUT DX, AL
        CALL INIT_LCD
        MOV AL, 080H                ; displays "Room 1"
        LEA SI, ROOM1_STR
        CALL DISPLAY_STR
        MOV AL, 0C0H                ; displays "Fan 1: "
        LEA SI, ROOM1_FAN1_STR
        CALL DISPLAY_STR
        MOV AL, 0C7H                ; displays "[OFF]"
        LEA SI, FAN_OFF_STR
        CALL DISPLAY_STR
        MOV AL, 094H                ; displays "Fan 2: "
        LEA SI, ROOM1_FAN2_STR
        CALL DISPLAY_STR
        MOV AL, 09BH                ; displays "[OFF]"
        LEA SI, FAN_OFF_STR
        CALL DISPLAY_STR
        MOV AL, 0D4H                ; displays "Temperature: "
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    ROOM2:
        MOV AT_ROOM_FLAG, 1
        MOV AT_ROOM1_FLAG, 0
        MOV AT_ROOM2_FLAG, 1
        MOV AT_ROOM3_FLAG, 0
        MOV DX, PORTE
        MOV AL, 02H
        OUT DX, AL
        CALL INIT_LCD
        MOV AL, 080H                ; displays "Room 2"
        LEA SI, ROOM2_STR
        CALL DISPLAY_STR
        MOV AL, 0C0H                ; displays "Fan 1: "
        LEA SI, ROOM2_FAN1_STR
        CALL DISPLAY_STR
        MOV AL, 0C7H                ; displays "[OFF]"
        LEA SI, FAN_OFF_STR
        CALL DISPLAY_STR
        MOV AL, 094H                ; displays "Fan 2: "
        LEA SI, ROOM2_FAN2_STR
        CALL DISPLAY_STR
        MOV AL, 09BH                ; displays "[OFF]"
        LEA SI, FAN_OFF_STR
        CALL DISPLAY_STR
        MOV AL, 0D4H                ; displays "Temperature: "
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    ROOM3:
        MOV AT_ROOM_FLAG, 1
        MOV AT_ROOM1_FLAG, 0
        MOV AT_ROOM2_FLAG, 0
        MOV AT_ROOM3_FLAG, 1
        MOV DX, PORTE
        MOV AL, 03H
        OUT DX, AL
        CALL INIT_LCD
        MOV AL, 080H                ; displays "Room 3"
        LEA SI, ROOM1_STR
        CALL DISPLAY_STR
        MOV AL, 0C0H                ; displays "Fan 1: "
        LEA SI, ROOM3_FAN1_STR
        CALL DISPLAY_STR
        MOV AL, 0C7H                ; displays "[OFF]"
        LEA SI, FAN_OFF_STR
        CALL DISPLAY_STR
        MOV AL, 094H                ; displays "Fan 2: "
        LEA SI, ROOM3_FAN2_STR
        CALL DISPLAY_STR
        MOV AL, 09BH                ; displays "[OFF]"
        LEA SI, FAN_OFF_STR
        CALL DISPLAY_STR
        MOV AL, 0D4H                ; displays "Temperature: "
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
        MOV AT_ROOM_FLAG, 0
        MOV DX, PORTE
        MOV AL, 00H
        OUT DX, AL
        JMP INIT
    FAN1:
        CMP AT_ROOM1_FLAG, 1
        JE AT_ROOM1
        CMP AT_ROOM2_FLAG, 1
        JE AT_ROOM2
        CMP AT_ROOM3_FLAG, 1
        JE AT_ROOM3
        AT_ROOM1:
            MOV DX, PORTJ
            MOV AL, 01H
            OUT DX, AL
            MOV AL, 0C7H                ; Update LCD to display "[ON] "
            LEA SI, FAN_ON_STR
            CALL DISPLAY_STR
            JMP CONT
        AT_ROOM2:
            MOV DX, PORTL
            MOV AL, 01H
            OUT DX, AL
            MOV AL, 0C7H                ; Update LCD to display "[ON] "
            LEA SI, FAN_ON_STR
            CALL DISPLAY_STR
            JMP CONT
        AT_ROOM3:
            MOV DX, PORTN
            MOV AL, 01H
            OUT DX, AL
            MOV AL, 0C7H                ; Update LCD to display "[ON] "
            LEA SI, FAN_ON_STR
            CALL DISPLAY_STR
            JMP CONT
    FIRST_FAN:
        CMP FAN1_FLAG, 1
        JE RESET_FAN1_FLAG
        CMP FAN2_FLAG, 1
        JE FANS_ROOM1
        MOV FAN1_FLAG, 1
        MOV DX, PORTI
        MOV AL, 01H
        OUT DX, AL
        MOV AL, 0C7H                ; Update LCD to display "[ON] "
        LEA SI, FAN_ON_STR
        CALL DISPLAY_STR
        JMP EXIT_FAN_1
        FANS_ROOM1:
            MOV DX, PORTI
            MOV AL, 03H
            OUT DX, AL
            MOV AL, 0C7H                ; Update LCD to display "[ON] "
            LEA SI, FAN_ON_STR
            CALL DISPLAY_STR
            MOV AL, 09BH                ; Update LCD to display "[ON] "
            LEA SI, FAN_ON_STR
            CALL DISPLAY_STR
            JMP EXIT_FAN_1
        RESET_FAN1_FLAG:
            MOV FAN1_FLAG, 0
            MOV DX, PORTI
            MOV AL, 00H
            OUT DX, AL
            MOV AL, 0C7H                ; Update LCD to display "[OFF]"
            LEA SI, FAN_OFF_STR
            CALL DISPLAY_STR
        EXIT_FAN_1:
        JMP CONT
    SECOND_FAN:
        CMP FAN2_FLAG, 1
        JE RESET_FAN2_FLAG
        CMP FAN1_FLAG, 1
        JE FANS_ROOM2
        MOV FAN2_FLAG, 1
        MOV DX, PORTI
        MOV AL, 02H
        OUT DX, AL
        MOV AL, 0C7H                ; Update LCD to display "[OFF]"
        LEA SI, FAN_OFF_STR
        CALL DISPLAY_STR
        JMP EXIT_FAN_2
        FANS_ROOM2:
            MOV DX, PORTI
            MOV AL, 03H
            OUT DX, AL
            MOV AL, 0C7H                ; Update LCD to display "[ON] "
            LEA SI, FAN_ON_STR
            CALL DISPLAY_STR
            MOV AL, 09BH                ; Update LCD to display "[ON] "
            LEA SI, FAN_ON_STR
            CALL DISPLAY_STR
            JMP EXIT_FAN_2
        RESET_FAN2_FLAG:
            MOV FAN2_FLAG, 0
            MOV DX, PORTI
            MOV AL, 00H
            OUT DX, AL
            MOV AL, 09BH                ; Update LCD to display "[OFF]"
            LEA SI, FAN_OFF_STR
            CALL DISPLAY_STR
        EXIT_FAN_2:
        JMP CONT

        CONT:
            CALL DELAY_1MS
            JMP MENU_CHECK_DAVBL

    ; MODULE: fetch data from temperature sensor using ADC
    ; ADDC ADDB ADDA
    ;  0    0    0    =  TEMPSEN_1
    ;  0    0    1    =  TEMPSEN_2
    ;  0    1    0    =  TEMPSEN_3
    READ_ADC:
        MOV DX, PORTD       ; select ADC out port
        IN AL, DX           ; store digital data to AL
        MOV ADC_CURR, AL
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

    ; MODULE: Convert the digital data from ADC to a string format and convert to a certain speed
    ; 16			    21			    26
    ; 17			    22			    27
    ; 18    Speed 3	    23  Speed 2	    28  Speed 1
    ; 19			    24			    29
    ; 20			    25			    30
    ADC_DATA_CONVERTER:
        MOV AL, ADC_CURR
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
        CMP AL, 033H
        JE TEMP_30
    RET

    HANDLE_ROOM:
        CMP AT_ROOM1_FLAG, 1
        JE ROOM01
        CMP AT_ROOM2_FLAG, 1
        JE ROOM02
        CMP AT_ROOM3_FLAG, 1
        JE ROOM03
        JMP CONT1

        ROOM01:
            MOV DX, PORTK
            JMP CONT1
        ROOM02:
            MOV DX, PORTM
            JMP CONT1
        ROOM03:
            MOV DX, PORTO
    CONT1:
    RET

        TEMP_16:
            CALL HANDLE_ROOM
            MOV AL, 03H
            OUT DX, AL
            LEA SI, T16
        RET
        TEMP_17:
            CALL HANDLE_ROOM
            MOV AL, 03H
            OUT DX, AL
            LEA SI, T17
        RET
        TEMP_18:
            CALL HANDLE_ROOM
            MOV AL, 03H
            OUT DX, AL
            LEA SI, T18
        RET
        TEMP_19:
            CALL HANDLE_ROOM
            MOV AL, 03H
            OUT DX, AL
            LEA SI, T19
        RET
        TEMP_20:
            CALL HANDLE_ROOM
            MOV AL, 03H
            OUT DX, AL
            LEA SI, T20
        RET
        TEMP_21:
            CALL HANDLE_ROOM
            MOV AL, 02H
            OUT DX, AL
            LEA SI, T21
        RET
        TEMP_22:
            CALL HANDLE_ROOM
            MOV AL, 02H
            OUT DX, AL
            LEA SI, T22
        RET
        TEMP_23:
            CALL HANDLE_ROOM
            MOV AL, 02H
            OUT DX, AL
            LEA SI, T23
        RET
        TEMP_24:
            CALL HANDLE_ROOM
            MOV AL, 02H
            OUT DX, AL
            LEA SI, T24
        RET
        TEMP_25:
            CALL HANDLE_ROOM
            MOV AL, 02H
            OUT DX, AL
            LEA SI, T25
        RET
        TEMP_26:
            CALL HANDLE_ROOM
            MOV AL, 01H
            OUT DX, AL
            LEA SI, T26
        RET
        TEMP_27:
            CALL HANDLE_ROOM
            MOV AL, 01H
            OUT DX, AL
            LEA SI, T27
        RET
        TEMP_28:
            CALL HANDLE_ROOM
            MOV AL, 01H
            OUT DX, AL
            LEA SI, T28
        RET
        TEMP_29:
            CALL HANDLE_ROOM
            MOV AL, 01H
            OUT DX, AL
            LEA SI, T29
        RET
        TEMP_30:
            CALL HANDLE_ROOM
            MOV AL, 01H
            OUT DX, AL
            LEA SI, T30
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
