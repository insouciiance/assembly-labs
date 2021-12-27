.SALL

INCLUDE MACRO.LIB
PURGE PRINTNUM

STSEG SEGMENT PARA STACK 'Stack'
    DW 64 DUP (?)
STSEG ENDS

DSEG SEGMENT PARA 'Data'
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
    
    PROMPTX DB 'Enter x11:', '$'
    PROMPTY DB 'Enter y22:', '$'
    ERRORMSG DB 'Entered number was invalid.', '$'
    
    NUMX DW ?
    NUMY DW ?
    NUMH DW ?
    NUML DW ?
    POSITION DW 1
    NUMRADIX DW 10
    
    FUNC1AUX DW 0
    FUNC2DIVISOR DW 0
    FUNC3MULTIPLIER DW 2
    
    CAST_DIVISOR DW 0
    DECIMAL_PRECISION DB 5
    
    ISERROR DB ?
DSEG ENDS

CSEG SEGMENT PARA 'Code'
    BEGIN PROC FAR
    INIT CSEG, DSEG, STSEG ; MACRO
        
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
            JMP RETURN_INT
            CHECKFUNC2:
                CMP NUMX, 01H
                JG CHECKFUNC1
                CALL FUNC2
                JMP RETURN_DECIMAL
                CHECKFUNC1:
                    CMP NUMX, 03H
                    JG INPUT_Y
                    CALL FUNC1
                    JMP RETURN_DECIMAL
                    INPUT_Y:
                        MOV ISERROR, 0
                        CALL INPUTY
                        CMP ISERROR, 0
                        JG INPUT_Y
                        CALL CASTY
                        CMP ISERROR, 0
                        JG INPUT_Y
                        CALL FUNC4
                        JMP RETURN_INT
            RETURN_INT:
                CALL CASTRESULT
                RET
            RETURN_DECIMAL:
                CALL CASTDECIMAL
                RET
    BEGIN ENDP
    
    INPUTX PROC NEAR
        MOV AH, 09H
        LEA DX, PROMPTX
        INT 21H
            
        NEWLINE ; MACRO

        MOV AH, 0AH  
        LEA DX, XPAR
        INT 021H
        
        NEWLINE ; MACRO
        RET
    INPUTX ENDP
    
    INPUTY PROC NEAR
        MOV AH, 09H
        LEA DX, PROMPTY
        INT 21H
            
        NEWLINE ; MACRO

        MOV AH, 0AH  
        LEA DX, YPAR
        INT 021H
        
        NEWLINE ; MACRO
        RET
    INPUTY ENDP
    
    CASTX PROC NEAR
        MOV NUMX, 0
        MOV POSITION, 01H
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
            JL RETURNERR_CASTX
            CMP AL, 039H
            JG RETURNERR_CASTX
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERR_CASTX
            ADD NUMX, AX
            JNO NEXT_CASTX
            CMP NUMX, MIN
            JNE RETURNERR_CASTX
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNERR_CASTX
            NEXT_CASTX:
                DEC BX
                CMP CX, 01H
                JE PRERETURN_CASTX
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR_CASTX
                MOV POSITION, AX
                LOOP PROCESS_DIGITX
        PRERETURN_CASTX:
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURN_CASTX
            NEG NUMX
        RETURN_CASTX:
            RET
        RETURNERR_CASTX:
            DOS21 ERRORMSG ; MACRO
            NEWLINE ; MACRO
            MOV ISERROR, 01H
            RET
    CASTX ENDP
    
    CASTY PROC NEAR
        MOV NUMY, 0
        MOV POSITION, 01H
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
            JL RETURNERR_CASTY
            CMP AL, 039H
            JG RETURNERR_CASTY
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERR_CASTY
            ADD NUMY, AX
            JNO NEXT_CASTY
            CMP NUMY, MIN
            JNE RETURNERR_CASTY
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNERR_CASTY
            NEXT_CASTY:
                DEC BX
                CMP CX, 01H
                JE PRERETURN_CASTY
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR_CASTY
                MOV POSITION, AX
                LOOP PROCESS_DIGITY
        PRERETURN_CASTY:
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURN_CASTY
            NEG NUMY
        RETURN_CASTY:
            RET
        RETURNERR_CASTY:
            DOS21 ERRORMSG ; MACRO
            NEWLINE ; MACRO
            MOV ISERROR, 01H
            RET
    CASTY ENDP

    FUNC1 PROC NEAR ; result = 35 / X + X^3
        MOV AX, 35
        IDIV NUMX
        MOV BX, NUMX
        MOV CAST_DIVISOR, BX
        MOV NUMH, DX        
        MOV FUNC1AUX, AX
        MOV AX, NUMX
        IMUL NUMX
        IMUL NUMX
        ADD AX, FUNC1AUX
        MOV NUML, AX
        RET
    FUNC1 ENDP
    
    FUNC2 PROC NEAR ; result = X / (X^2 + 1)
        MOV AX, NUMX
        IMUL NUMX
        INC AX
        MOV FUNC2DIVISOR, AX
        MOV BX, FUNC2DIVISOR
        MOV CAST_DIVISOR, BX
        MOV AX, NUMX
        MOV DX, 0
        IDIV FUNC2DIVISOR
        MOV NUML, AX
        MOV NUMH, DX
        RET
    FUNC2 ENDP
    
    FUNC3 PROC NEAR ; result = 2X
        MOV AX, NUMX
        IMUL FUNC3MULTIPLIER
        MOV NUMH, DX
        MOV NUML, AX
        RET
    FUNC3 ENDP
    
    FUNC4 PROC NEAR ; result = X + Y
        MOV AX, NUMX
        CMP NUMY, 0
        JGE ADDY
        NEG NUMY
        SUB AX, NUMY
        MOV NUML, AX
        MOV NUMH, 0
        JNS RETURNFUNC4
        SBB NUMH, 0
        JMP RETURNFUNC4
        ADDY:
            ADD AX, NUMY
            MOV NUML, AX
            MOV NUMH, 0
            ADC NUMH, 0
            RETURNFUNC4:
            RET
    FUNC4 ENDP
    
    CASTRESULT PROC NEAR
        CMP NUMH, 0
        JGE CAST_1
        MOV AL, '-'
        INT 29H
        NOT NUMH
        NOT NUML
        ADD NUML, 01H
        ADC NUMH, 0
        CAST_1:
            MOV CX, 0
            MOV BX, 0AH
            MOV DX, NUMH
            MOV AX, NUML
        CAST_2:
            IDIV BX
            OR DL, 030H
            PUSH DX
            INC CX
            MOV DX, 0
            TEST AX, AX
            JNZ CAST_2
        CAST_3:
            POP AX
            INT 029H
            LOOP CAST_3
        RET
    CASTRESULT ENDP
    
    CASTDECIMAL PROC NEAR 
        CMP NUML, 0
        JGE CAST_INT1
        MOV AL, '-'
        INT 29H
        NEG NUML
        CAST_INT1:
            MOV CX, 0
            MOV BX, 0AH
            MOV AX, NUML
            MOV DX, 0
        CAST_INT2:
            IDIV BX
            OR DL, 030H
            PUSH DX
            INC CX
            MOV DX, 0
            TEST AX, AX
            JNZ CAST_INT2
        CAST_INT3:
            POP AX
            INT 029H
            LOOP CAST_INT3
            
        CMP NUMH, 0
        JE DECIMAL_RETURN
            
        MOV AX, 02EH ; dot(.)
        INT 029H
            
        MOV AX, NUMH
        CAST_DECIMAL1:
            IMUL NUMRADIX
            IDIV CAST_DIVISOR
            OR AX, 030H
            INT 029H
            MOV AX, DX
            DEC DECIMAL_PRECISION
            CMP DECIMAL_PRECISION, 0
            JLE DECIMAL_RETURN
            CMP AX, 0
            JE DECIMAL_RETURN
            JMP CAST_DECIMAL1 
        DECIMAL_RETURN: 
            RET
    CASTDECIMAL ENDP
CSEG ENDS
END BEGIN