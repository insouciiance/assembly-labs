STSEG SEGMENT PARA STACK 'Stack'
    DW 32 DUP(?)
STSEG ENDS

DSEG SEGMENT PARA 'Data'
    CR EQU 0DH
    LF EQU 0AH
    
    NUMPAR LABEL BYTE
    MAXLEN DB 20
    NUMLEN DB ?
    NUMFLD DB 20 DUP(' '), '$'
    
    PROMPT DB 'Number?', '$'
    ERRORMSG DB 'Entered number was invalid.', '$'
    NUM DW 0
    POSITION DW 1
    NUMRADIX DW 10
    MULTIPLIER DW 7
    ISERROR DB 0
DSEG ENDS

CSEG SEGMENT PARA 'Code'
    BEGIN PROC FAR
        ASSUME CS:CSEG, DS:DSEG, SS:STSEG
        PUSH DS
        MOV AX, 0
        PUSH AX
        MOV AX, DSEG
        MOV DS, AX
        
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
        MOV AH, 09
        LEA DX, PROMPT
        INT 21H
            
        CALL NEWLINE

        MOV AH, 0AH  
        LEA DX, NUMPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTNUM ENDP

    NEWLINE PROC NEAR
        MOV DL, CR
        MOV AH, 02h
        INT 21H
        MOV DL, LF
        MOV AH, 02h
        INT 21H
        RET
    NEWLINE ENDP
    
    CASTNUM PROC NEAR
        MOV NUM, 0
        MOV POSITION, 1
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
            MUL POSITION
            ADD NUM, AX
            CMP NUM, 4681
            JG RETURNERR
            CMP NUM, -4681
            JL RETURNERR
            DEC BX
            MOV AX, POSITION
            MUL NUMRADIX
            MOV POSITION, AX
            LOOP PROCESS_DIGIT
        MOV AX, [SI]
        CMP AL, '-'
        JNE RETURN
        NEG NUM
        RETURN:
            RET
        RETURNERR:
            CALL PRINTERR
            MOV ISERROR, 1
            RET
    CASTNUM ENDP
    
    CASTRESULT PROC NEAR
        CMP NUM, 0
        JGE M1
        MOV AL, '-'
        INT 29H
        NEG NUM
        M1:
            MOV AX, NUM
            MOV CX, 0
            MOV BX, 0AH
        M2:
            MOV DX, 0
            DIV BX
            OR DL, 030H
            PUSH DX
            INC CX
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
        MOV NUM, AX
        RET
    MULNUM ENDP
    
    PRINTERR PROC NEAR
        MOV AH, 09H
        LEA DX, ERRORMSG
        INT 021H 
        CALL NEWLINE
        RET
    PRINTERR ENDP
CSEG ENDS
END BEGIN