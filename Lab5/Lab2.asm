.SALL

INCLUDE MACRO.LIB
PURGE PRINTNUM

STSEG SEGMENT PARA STACK 'Stack'
    DW 32 DUP(?)
STSEG ENDS

DSEG SEGMENT PARA 'Data'
    CR EQU 0DH
    LF EQU 0AH
    MIN EQU -32768
    MAX EQU 32767
    
    NUMPAR LABEL BYTE
    MAXLEN DB 20
    NUMLEN DB ?
    NUMFLD DB 20 DUP(' '), '$'
    
    PROMPT DB 'Number?3', '$'
    ERRORMSG DB 'Entered number was invalid.', '$'
    NUM DW 0
    NUMH DW 0
    NUML DW 0
    POSITION DW 1
    NUMRADIX DW 10
    MULTIPLIER DW 7
    ISERROR DB 0
DSEG ENDS

CSEG SEGMENT PARA 'Code'
    BEGIN PROC FAR
        INIT CSEG, DSEG, STSEG ; MACRO
        INPUT:
            MOV ISERROR, 0
            CALL INPUTNUM
            CMP ISERROR, 0
            JG INPUT
            CALL CASTNUM
            CMP ISERROR, 0
            JG INPUT
            CALL MULNUM
            CALL CASTRESULT
            RET
    BEGIN ENDP

    INPUTNUM PROC NEAR
        MOV AH, 09H
        LEA DX, PROMPT
        INT 21H
            
        NEWLINE ; MACRO

        MOV AH, 0AH  
        LEA DX, NUMPAR
        INT 021H
        
        NEWLINE ; MACRO
        RET
    INPUTNUM ENDP
    
    CASTNUM PROC NEAR
        MOV NUM, 0
        MOV POSITION, 01H
        MOV CH, 0    
        MOV CL, NUMLEN
        MOV BX, CX
        DEC BX
        LEA SI, NUMFLD
        MOV AX, [SI]
        CMP AL, '-'
        JNE PROCESS_DIGIT
        DEC CX
        PROCESS_DIGIT:
            MOV AH, 0
            MOV AL, [SI + BX]
            CMP AL, 030H
            JL RETURNERR
            CMP AL, 039H
            JG RETURNERR
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERR
            ADD NUM, AX
            JNO NEXT
            CMP NUM, MIN
            JNE RETURNERR
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNERR
            NEXT:
                DEC BX
                CMP CX, 1
                JE PRERETURN
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR
                MOV POSITION, AX
                LOOP PROCESS_DIGIT
        PRERETURN:
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURN
            NEG NUM
        RETURN:
            RET
        RETURNERR:
            DOS21 ERRORMSG ; MACRO
            NEWLINE ; MACRO
            MOV ISERROR, 01H
            RET
    CASTNUM ENDP
    
    CASTRESULT PROC NEAR
        CMP NUMH, 0
        JGE M1
        MOV AL, '-'
        INT 29H
        NOT NUMH
        NOT NUML
        ADD NUML, 01H
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

    MULNUM PROC NEAR
        MOV AX, NUM
        IMUL MULTIPLIER
        MOV NUMH, DX
        MOV NUML, AX
        RET
    MULNUM ENDP
CSEG ENDS
END BEGIN