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
    
    ARRNUMPAR LABEL BYTE
    ARRNUMMAXLEN DB 20
    ARRNUMLEN DB ?
    ARRNUMFLD DB 20 DUP(' '), '$'
    
    ARRAY DW 10 DUP (?)
    ARRNUM DW 0
    
    ARRAY_OFFSET DW 0
    
    MAXNUM DW MIN
    
    PROMPT DB 'Enter array length (max. 10):', '$'
    ERRORMSG DB 'Entered number was invalid.', '$'
    MAXNUMMSG DB 'Max number: ', '$'
    SUMMSG DB 'Elements sum: ', '$'
    ENTERARRAYMSG DB 'Now enter array elements: ', '$'
    PRINTARRAYMSG DB 'Sorted array: ', '$'
    
    NUM DW 0
    SUMH DW 0
    SUML DW 0
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
            CALL INPUTARR
            CMP ISERROR, 0
            JG INPUT
            CALL FINDMAX
            CALL PRINTMAXNUM
            CALL FINDSUM
            CALL PRINTSUM
            CALL SORTARRAY
            CALL PRINTARRAY
            RET
    BEGIN ENDP
    
    INPUTARR PROC NEAR
        MOV AH, 09H
        LEA DX, ENTERARRAYMSG
        INT 21H
        CALL NEWLINE
        MOV CX, NUM
        MOV ARRAY_OFFSET, 0
        PROCESS_ARRNUM:
            PUSH CX
            CALL INPUTARRNUM
            CALL CASTARRNUM
            CMP ISERROR, 0
            JG RETURNERR_INPUTARR
            MOV AX, ARRNUM
            MOV BX, ARRAY_OFFSET
            MOV ARRAY + BX, AX
            INC ARRAY_OFFSET
            INC ARRAY_OFFSET
            POP CX
            LOOP PROCESS_ARRNUM
            RET
        RETURNERR_INPUTARR:
            POP CX
            RET
    INPUTARR ENDP
    
    PRINTARRAY PROC NEAR
        MOV AH, 09H
        LEA DX, PRINTARRAYMSG
        INT 21H
        CALL NEWLINE
        
        MOV CX, NUM
        MOV ARRAY_OFFSET, 0
        PRINT_ARRNUM:
            PUSH CX
            MOV BX, ARRAY_OFFSET
            MOV AX, ARRAY + BX
            MOV ARRNUM, AX
            CALL PRINTARRNUM
            CALL NEWLINE
            INC ARRAY_OFFSET
            INC ARRAY_OFFSET
            POP CX
            LOOP PRINT_ARRNUM
        RET
    PRINTARRAY ENDP

    FINDMAX PROC NEAR
        MOV CX, NUM
        MOV ARRAY_OFFSET, 0
        CHECK_MAXNUM:
            PUSH CX
            MOV BX, ARRAY_OFFSET
            MOV AX, ARRAY + BX
            MOV ARRNUM, AX            
            CMP MAXNUM, AX
            JGE FINDMAX_CONTINUE
            MOV MAXNUM, AX
            FINDMAX_CONTINUE:
                INC ARRAY_OFFSET
                INC ARRAY_OFFSET
                POP CX
                LOOP CHECK_MAXNUM
        RET
    FINDMAX ENDP
    
    FINDSUM PROC NEAR
        MOV CX, NUM
        MOV ARRAY_OFFSET, 0
        ADD_SUM:
            PUSH CX
            MOV BX, ARRAY_OFFSET
            MOV AX, ARRAY + BX
            CMP AX, 0
            JGE ADD_ARRAYNUM
            NEG AX
            SUB SUML, AX
            SBB SUMH, 0
            JMP ADD_SUM_CONTINUE
            ADD_ARRAYNUM:      
                ADD SUML, AX
                ADC SUMH, 0
            ADD_SUM_CONTINUE:
                INC ARRAY_OFFSET
                INC ARRAY_OFFSET
                POP CX
                LOOP ADD_SUM
        RET
    FINDSUM ENDP
    
    SORTARRAY PROC NEAR
        MOV CX, NUM
        MOV ARRAY_OFFSET, 0
        CMP CX, 1
        JLE RETURN_SORTARRAY
        BUBBLE_SORT:
            PUSH CX
            MOV CX, NUM
            DEC CX
            MOV ARRAY_OFFSET, 0
            BUBBLE_SORT_INNER:
                MOV BX, ARRAY_OFFSET
                MOV AX, ARRAY + BX
                INC BX
                INC BX
                MOV DX, ARRAY + BX
                CMP AX, DX
                JLE SORT_CONTINUE
                MOV ARRAY + BX, AX
                DEC BX
                DEC BX
                MOV ARRAY + BX, DX
                SORT_CONTINUE:
                    INC ARRAY_OFFSET
                    INC ARRAY_OFFSET
                    LOOP BUBBLE_SORT_INNER
            POP CX
            LOOP BUBBLE_SORT
        RETURN_SORTARRAY:
            RET
    SORTARRAY ENDP
    
    INPUTNUM PROC NEAR
        MOV AH, 09H
        LEA DX, PROMPT
        INT 21H
            
        CALL NEWLINE

        MOV AH, 0AH  
        LEA DX, NUMPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTNUM ENDP
    
    INPUTARRNUM PROC NEAR
        MOV AH, 0AH  
        LEA DX, ARRNUMPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTARRNUM ENDP

    NEWLINE PROC NEAR
        MOV DL, CR
        MOV AH, 02H
        INT 21H
        MOV DL, LF
        MOV AH, 02H
        INT 21H
        RET
    NEWLINE ENDP
    
    CASTARRNUM PROC NEAR
        MOV ARRNUM, 0
        MOV POSITION, 01H
        MOV CH, 0    
        MOV CL, ARRNUMLEN
        MOV BX, CX
        DEC BX
        LEA SI, ARRNUMFLD
        MOV AX, [SI]
        CMP AL, '-'
        JNE PROCESS_DIGIT_CASTARRNUM
        DEC CX
        PROCESS_DIGIT_CASTARRNUM:
            MOV AH, 0
            MOV AL, [SI + BX]
            CMP AL, 030H
            JL RETURNERR_CASTARRNUM
            CMP AL, 039H
            JG RETURNERR_CASTARRNUM
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERR_CASTARRNUM
            ADD ARRNUM, AX
            JNO NEXT_CASTARRNUM
            CMP ARRNUM, MIN
            JNE RETURNERR_CASTARRNUM
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNERR_CASTARRNUM
            NEXT_CASTARRNUM:
                DEC BX
                CMP CX, 1
                JE PRERETURN_CASTARRNUM
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR_CASTARRNUM
                MOV POSITION, AX
                LOOP PROCESS_DIGIT_CASTARRNUM
                PRERETURN_CASTARRNUM:
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURN_CASTARRNUM
            NEG ARRNUM
        RETURN_CASTARRNUM:
            RET
        RETURNERR_CASTARRNUM:
            CALL PRINTERR
            MOV ISERROR, 01H
            RET
        CASTARRNUM ENDP
    
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
        JE RETURNERR
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
            JO RETURNERR
            CMP NUM, 0AH
            JG RETURNERR
            NEXT:
                DEC BX
                CMP CX, 1
                JE RETURN
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR
                MOV POSITION, AX
                LOOP PROCESS_DIGIT
        RETURN:
            CMP NUM, 0
            JLE RETURNERR
            RET
        RETURNERR:
            CALL PRINTERR
            MOV ISERROR, 01H
            RET
    CASTNUM ENDP
    
    PRINTARRNUM PROC NEAR
        CMP ARRNUM, 0
        JGE M1_PRINTARRNUM
        MOV AL, '-'
        INT 29H
        NEG ARRNUM
        M1_PRINTARRNUM:
            MOV CX, 0
            MOV BX, 0AH
            MOV DX, 0
            MOV AX, ARRNUM
        M2_PRINTARRNUM:
            IDIV BX
            OR DL, 030H
            PUSH DX
            INC CX
            MOV DX, 0
            TEST AX, AX
            JNZ M2_PRINTARRNUM
        M3_PRINTARRNUM:
            POP AX
            INT 029H
            LOOP M3_PRINTARRNUM
        RET
    PRINTARRNUM ENDP
    
    PRINTSUM PROC NEAR
        MOV AH, 09H
        LEA DX, SUMMSG
        INT 21H
        
        CMP SUMH, 0
        JGE M1
        MOV AL, '-'
        INT 29H
        NOT SUMH
        NOT SUML
        ADD SUML, 01H
        ADC SUMH, 0
        M1:
            MOV CX, 0
            MOV BX, 0AH
            MOV DX, SUMH
            MOV AX, SUML
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
        CALL NEWLINE
        RET
    PRINTSUM ENDP
    
    PRINTMAXNUM PROC NEAR
        MOV AH, 09H
        LEA DX, MAXNUMMSG
        INT 21H
    
        CMP MAXNUM, 0
        JGE M1_PRINTMAXNUM
        MOV AL, '-'
        INT 29H
        NEG MAXNUM
        M1_PRINTMAXNUM:
            MOV CX, 0
            MOV BX, 0AH
            MOV DX, 0
            MOV AX, MAXNUM
        M2_PRINTMAXNUM:
            IDIV BX
            OR DL, 030H
            PUSH DX
            INC CX
            MOV DX, 0
            TEST AX, AX
            JNZ M2_PRINTMAXNUM
        M3_PRINTMAXNUM:
            POP AX
            INT 029H
            LOOP M3_PRINTMAXNUM
        CALL NEWLINE
        RET
    PRINTMAXNUM ENDP
    
    PRINTERR PROC NEAR
        MOV AH, 09H
        LEA DX, ERRORMSG
        INT 021H 
        CALL NEWLINE
        RET
    PRINTERR ENDP
CSEG ENDS
END BEGIN