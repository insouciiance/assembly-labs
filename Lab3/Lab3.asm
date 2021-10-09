STSEG SEGMENT PARA STACK 'Stack'
    DW 64 DUP (?)
STSEG ENDS

DSEG SEGMENT PARA 'Data'
    CR EQU 0DH
    LF EQU 0AH
    MIN EQU -32768
    MAX EQU 32767
    
    XPAR LABEL BYTE
    XMAXLEN DB 20
    XLEN DB ?
    XFLD DB 20 DUP(' '), '$'
    
    YPAR LABEL BYTE
    YMAXLEN DB 20
    YLEN DB ?
    YFLD DB 20 DUP(' '), '$'
    
    PROMPTX DB 'Enter x:', '$'
    PROMPTY DB 'Enter y:', '$'
    ERRORMSG DB 'Entered number was invalid.', '$'
    NUMX DW ?
    NUMY DW ?
    NUMH DW ?
    NUML DW ?
    POSITION DW 1
    NUMRADIX DW 10
    
    FUNC1AUX DW 0
    FUNC2DIVISOR DB 0
    FUNC3MULTIPLIER DW 2
    
    ISERROR DB ?
DSEG ENDS

CSEG SEGMENT PARA 'Code'
    BEGIN PROC FAR
    ASSUME CS:CSEG, DS:DSEG, SS:STSEG
        PUSH DS
        MOV AX, 0
        PUSH AX
        MOV AX, DSEG
        MOV DS, AX
        
        INPUT_X:
            MOV ISERROR, 0
            CALL INPUTX
            CMP ISERROR, 0
            JG INPUT_X
            CALL CASTX
            CMP ISERROR, 0
            JG INPUT_X
            
            CMP NUMX, -01H
            JG CHECKFUNC2
            CALL FUNC3
            JMP RETURN
            CHECKFUNC2:
                CMP NUMX, 01H
                JG CHECKFUNC1
                CALL FUNC2
                JMP RETURN
                CHECKFUNC1:
                    CMP NUMX, 03H
                    JG INPUT_Y
                    CALL FUNC1
                    JMP RETURN
                    INPUT_Y:
                        MOV ISERROR, 0
                        CALL INPUTY
                        CMP ISERROR, 0
                        JG INPUT_Y
                        CALL CASTY
                        CMP ISERROR, 0
                        JG INPUT_Y
                        CALL FUNC4
                        JMP RETURN
            RETURN:
                CALL CASTRESULT
                RET
    BEGIN ENDP
    
    INPUTX PROC NEAR
        MOV AH, 09
        LEA DX, PROMPTX
        INT 21H
            
        CALL NEWLINE

        MOV AH, 0AH  
        LEA DX, XPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTX ENDP
    
    INPUTY PROC NEAR
        MOV AH, 09
        LEA DX, PROMPTY
        INT 21H
            
        CALL NEWLINE

        MOV AH, 0AH  
        LEA DX, YPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTY ENDP
    
    CASTX PROC NEAR
        MOV NUMX, 0
        MOV POSITION, 1
        MOV CH, 0    
        MOV CL, XLEN
        MOV BX, CX
        DEC BX
        LEA SI, XFLD
        MOV AX, [SI]
        CMP AL, '-'
        JNE PROCESS_DIGITX
        DEC CX
        PROCESS_DIGITX:
            MOV AH, 0
            MOV AL, [SI + BX]
            CMP AL, 030H
            JL RETURNERRCASTX
            CMP AL, 039H
            JG RETURNERRCASTX
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERRCASTX
            ADD NUMX, AX
            JNO NEXTCASTX
            CMP NUMX, MIN
            JNE RETURNERRCASTX
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNERRCASTX
            NEXTCASTX:
                DEC BX
                CMP CX, 1
                JE PRERETURNCASTX
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERRCASTX
                MOV POSITION, AX
                LOOP PROCESS_DIGITX
        PRERETURNCASTX:
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNCASTX
            NEG NUMX
        RETURNCASTX:
            RET
        RETURNERRCASTX:
            CALL PRINTERR
            MOV ISERROR, 1
            RET
    CASTX ENDP
    
    CASTY PROC NEAR
        MOV NUMY, 0
        MOV POSITION, 1
        MOV CH, 0    
        MOV CL, YLEN
        MOV BX, CX
        DEC BX
        LEA SI, YFLD
        MOV AX, [SI]
        CMP AL, '-'
        JNE PROCESS_DIGITY
        DEC CX
        PROCESS_DIGITY:
            MOV AH, 0
            MOV AL, [SI + BX]
            CMP AL, 030H
            JL RETURNERRCASTY
            CMP AL, 039H
            JG RETURNERRCASTY
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERRCASTY
            ADD NUMY, AX
            JNO NEXTCASTY
            CMP NUMY, MIN
            JNE RETURNERRCASTY
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNERRCASTY
            NEXTCASTY:
                DEC BX
                CMP CX, 1
                JE PRERETURNCASTY
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERRCASTY
                MOV POSITION, AX
                LOOP PROCESS_DIGITY
        PRERETURNCASTY:
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNCASTY
            NEG NUMY
        RETURNCASTY:
            RET
        RETURNERRCASTY:
            CALL PRINTERR
            MOV ISERROR, 1
            RET
    CASTY ENDP

    FUNC1 PROC NEAR
        MOV AX, 35
        IDIV NUMX
        MOV FUNC1AUX, AX
        MOV AX, NUMX
        IMUL NUMX
        IMUL NUMX
        ADD AX, FUNC1AUX
        MOV NUML, AX
        MOV NUMH, 0
        RET
    FUNC1 ENDP
    
    FUNC2 PROC NEAR
        MOV AX, NUMX
        IMUL NUMX
        INC AL
        MOV FUNC2DIVISOR, AL
        MOV AX, NUMX
        IDIV FUNC2DIVISOR
        MOV AH, 0
        MOV NUML, AX
        MOV NUMH, 0
    FUNC2 ENDP
    
    FUNC3 PROC NEAR
        MOV AX, NUMX
        IMUL FUNC3MULTIPLIER
        MOV NUMH, DX
        MOV NUML, AX
        RET
    FUNC3 ENDP
    
    FUNC4 PROC NEAR
        MOV AX, NUMX
        ADD AX, NUMY
        MOV NUML, AX
        MOV NUMH, 0
        ADC NUMH, 0
        RET
    FUNC4 ENDP
    
    CASTRESULT PROC NEAR
        CMP NUMH, 0
        JGE M1
        MOV AL, '-'
        INT 29H
        NOT NUMH
        NOT NUML
        ADD NUML, 1
        ADC NUMH, 0
        M1:
            MOV CX, 0
            MOV BX, 0AH
            MOV DX, NUMH
            MOV AX, NUML
        M2:
            IDIV BX
            OR DL, 030H
            PUSH DX
            INC CX
            MOV DX, 0
            TEST AX, AX
            JNZ M2
        M3:
            POP AX
            INT 029H
            LOOP M3
        RET
    CASTRESULT ENDP
    
    PRINTERR PROC NEAR
        MOV AH, 09H
        LEA DX, ERRORMSG
        INT 021H 
        CALL NEWLINE
        RET
    PRINTERR ENDP
    
    NEWLINE PROC NEAR
        MOV DL, CR
        MOV AH, 02h
        INT 21H
        MOV DL, LF
        MOV AH, 02h
        INT 21H
        RET
    NEWLINE ENDP
CSEG ENDS
END BEGIN