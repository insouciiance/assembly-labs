INCLUDE MACRO.LIB

STSEG SEGMENT PARA STACK 'Stack'
    DW 32 DUP(?)
STSEG ENDS

DSEG SEGMENT PARA 'Data'
    MIN EQU -32768
    MAX EQU 32767
    
    PROMPT DB 'Enter array length (max. 10):', '$'
    ERRORMSG DB 'Entered number was invalid.', '$'
    MAXNUMMSG DB 'Max number: ', '$'
    SUMMSG DB 'Elements sum: ', '$'
    ENTERARRAYMSG DB 'Now enter array elements: ', '$'
    PRINTARRAYMSG DB 'Sorted array: ', '$'
    
    NUMPAR LABEL BYTE
    MAXLEN DB 20
    NUMLEN DB ?
    NUMFLD DB 20 DUP(' '), '$'
    
    ARRNUMPAR LABEL BYTE
    ARRNUMMAXLEN DB 20
    ARRNUMLEN DB ?
    ARRNUMFLD DB 20 DUP(' '), '$'
    
    NUM DW 0
    
    ARRAY DW 10 DUP (?)
    ARRNUM DW 0
    
    ARRAY_OFFSET DW 0
    
    MAXNUM DW MIN
    SUMH DW 0
    SUML DW 0
    
    POSITION DW 1
    NUMRADIX DW 10
    MULTIPLIER DW 7
    ISERROR DB 0
DSEG ENDS

CSEG SEGMENT PARA 'Code'
    BEGIN PROC FAR
        INIT CSEG, DSEG, STSEG ; MACRO
        
        INPUT_NUM:
            MOV ISERROR, 0
            CALL INPUTNUM
            CALL CASTNUM
            CMP ISERROR, 0
            JG INPUT_NUM
            INPUT_ARR:
                MOV ISERROR, 0
                CALL INPUTARR
                CMP ISERROR, 0
                JG INPUT_ARR
                CALL FINDMAX
                DOS21 MAXNUMMSG ; MACRO
                PRINTNUM MAXNUM ; MACRO
                NEWLINE ; MACRO
                CALL FINDSUM
                CALL PRINTSUM
                CALL SORTARRAY
                CALL PRINTARRAY
                RET
    BEGIN ENDP
    
    INPUTNUM PROC NEAR
        DOS21 PROMPT ; MACRO
            
        NEWLINE ; MACRO

        MOV AH, 0AH  
        LEA DX, NUMPAR
        INT 021H
        
        NEWLINE ; MACRO
        RET
    INPUTNUM ENDP
    
    INPUTARR PROC NEAR
        MOV AH, 09H
        LEA DX, ENTERARRAYMSG
        INT 21H
        NEWLINE ; MACRO
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
    
    INPUTARRNUM PROC NEAR
        MOV AH, 0AH  
        LEA DX, ARRNUMPAR
        INT 021H
        
        NEWLINE ; MACRO
        RET
    INPUTARRNUM ENDP

    PRINTARRAY PROC NEAR
        DOS21 PRINTARRAYMSG ; MACRO
        NEWLINE ; MACRO
        
        MOV CX, NUM
        MOV ARRAY_OFFSET, 0
        PRINT_ARRNUM:
            PUSH CX
            MOV BX, ARRAY_OFFSET
            MOV AX, ARRAY + BX
            MOV ARRNUM, AX
            PRINTNUM ARRNUM ; MACRO
            NEWLINE ; MACRO
            INC ARRAY_OFFSET
            INC ARRAY_OFFSET
            POP CX
            LOOP PRINT_ARRNUM
        RET
    PRINTARRAY ENDP
    
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
            DOS21 ERRORMSG
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
            DOS21 ERRORMSG
            MOV ISERROR, 01H
            RET
    CASTNUM ENDP
    
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
    
    PRINTSUM PROC NEAR
        DOS21 SUMMSG ; MACRO
        
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
        NEWLINE ; MACRO
        RET
    PRINTSUM ENDP
CSEG ENDS
END BEGIN