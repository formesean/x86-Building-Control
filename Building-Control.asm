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
    TEMP DB 0
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
    MOV AL, 10011011B
    OUT DX, AL
    MOV DX, COM_REG4
    MOV AL, 10001001B
    OUT DX, AL

    INIT:
    MOV AL, 00H
    OUT PORTJ, AL
    CALL INIT_LCD
    CALL SHOW_MENU
    CALL MENU_CHECK_DAVBL
    JMP ENDLESS

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
        CALL TEMP_SEN_1
        CALL INIT_LCD
        MOV AL, 080H
        LEA SI, ROOM1_STR
        CALL DISPLAY_STR
        MOV AL, 094H
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    ROOM2:
        CALL TEMP_SEN_2
        CALL INIT_LCD
        MOV AL, 080H
        LEA SI, ROOM2_STR
        CALL DISPLAY_STR
        MOV AL, 094H
        LEA SI, TEMP_STR
        CALL DISPLAY_STR
        JMP CONT
    ROOM3:
        CALL TEMP_SEN_3
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
        JMP INIT

        CONT:
            CALL DELAY_1MS
            JMP MENU_CHECK_DAVBL

    ; MODULE: fetch data from temperature sensor
    TEMP_SEN_1:
        MOV DX, PORTD
        IN AL, DX
        MOV DX, PORTJ
        OUT DX, AL
    RET

    TEMP_SEN_2:
        MOV DX, PORTE
        IN AL, DX
        MOV DX, PORTJ
        OUT DX, AL
    RET

    TEMP_SEN_3:
        MOV DX, PORTF
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

    DISPLAY_STR: CALL INST_CTRL
    DISP:
        MOV AL, [SI]
        CMP AL, '$'
        JE EXIT
        CALL DATA_CTRL
        INC SI
        JMP DISP
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
