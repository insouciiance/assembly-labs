STSEG SEGMENT PARA STACK 'Stack'
    DW 32 DUP(?)
STSEG ENDS

DSEG SEGMENT PARA 'Data'
    CR EQU 0DH
    LF EQU 0AH
    
    MIN EQU -32768
    MAX EQU 32767
    
    PROMPTROWS DB 'Enter number of rows (max.10):', '$'
    PROMPTCOLS DB 'Enter number of columns (max.10):', '$'
    ERRORMSG DB 'Entered number was invalid.', '$'
    INPUTARRAYMSG DB 'Now enter array elements:', '$'
    PRINTARRAYMSG DB 'Entered array:', '$'
    PROMPTFINDNUM DB 'Enter number to search:', '$'
    INCLUSIONSMSG DB 'Indexes of inclusions:', '$'
    NOTFOUNDMSG DB '[No match]', '$'
    
    ROWSPAR LABEL BYTE
    ROWSMAXLEN DB 20
    ROWSLEN DB ?
    ROWSFLD DB 20 DUP(' '), '$'
    
    COLSPAR LABEL BYTE
    COLSMAXLEN DB 20
    COLSLEN DB ?
    COLSFLD DB 20 DUP (' '), '$'
    
    ARRNUMPAR LABEL BYTE
    ARRNUMMAXLEN DB 20
    ARRNUMLEN DB ?
    ARRNUMFLD DB 20 DUP(' '), '$'
    
    FINDNUMPAR LABEL BYTE
    FINDNUMMAXLEN DB 20
    FINDNUMLEN DB ?
    FINDNUMFLD DB 20 DUP (' '), '$'
    
    ROWSNUM DW 0
    COLSNUM DW 0
    
    ARRAY DW 100 DUP (?)
    ARRNUM DW 0
    ARRNUM_SIZE DW 2
    
    ARRAYI DW 0
    ARRAYJ DW 0
    ARRAY_OFFSET DW 0
    
    FINDNUM DW 0

    CHAR DB ?
    
    POSITION DW 1
    NUMRADIX DW 10
    MULTIPLIER DW 7
    ISERROR DB 0
    ISNUMFOUND DB 0
DSEG ENDS

CSEG SEGMENT PARA 'Code'
    BEGIN PROC FAR
        ASSUME CS:CSEG, DS:DSEG, SS:STSEG
        PUSH DS
        MOV AX, 0
        PUSH AX
        MOV AX, DSEG
        MOV DS, AX
        
        INPUT_ROWS:
            MOV ISERROR, 0
            CALL INPUTROWS
            CALL CASTROWS
            CMP ISERROR, 0
            JG INPUT_ROWS
            INPUT_COLS:
                MOV ISERROR, 0
                CALL INPUTCOLS
                CALL CASTCOLS
                CMP ISERROR, 0
                JG INPUT_COLS
                INPUT_ARR:
                    MOV ISERROR, 0
                    CALL INPUTARR
                    CMP ISERROR, 0
                    JG INPUT_ARR
                    CALL PRINTARR
                    INPUT_FINDNUM:
                        MOV ISERROR, 0
                        CALL INPUTFINDNUM
                        CALL CASTFINDNUM
                        CMP ISERROR, 0
                        JG INPUT_FINDNUM
                        CALL PRINTINCLUSIONS
            RET
    BEGIN ENDP
    
    INPUTROWS PROC NEAR
        MOV AH, 09H
        LEA DX, PROMPTROWS
        INT 21H
            
        CALL NEWLINE

        MOV AH, 0AH  
        LEA DX, ROWSPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTROWS ENDP
    
    INPUTCOLS PROC NEAR
        MOV AH, 09H
        LEA DX, PROMPTCOLS
        INT 21H
            
        CALL NEWLINE

        MOV AH, 0AH  
        LEA DX, COLSPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTCOLS ENDP
    
    INPUTARRNUM PROC NEAR
        MOV AH, 0AH  
        LEA DX, ARRNUMPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTARRNUM ENDP

    INPUTFINDNUM PROC NEAR
        MOV AH, 09H
        LEA DX, PROMPTFINDNUM
        INT 21H
            
        CALL NEWLINE

        MOV AH, 0AH  
        LEA DX, FINDNUMPAR
        INT 021H
        
        CALL NEWLINE
        RET
    INPUTFINDNUM ENDP
    
    INPUTARR PROC NEAR
        MOV AH, 09H
        LEA DX, INPUTARRAYMSG
        INT 21H
        CALL NEWLINE
    
        MOV ARRAY_OFFSET, 0
        MOV AX, ROWSNUM
        IMUL COLSNUM
        MOV CX, AX
        INPUT_ARRNUM:
            PUSH CX
            CALL INPUTARRNUM
            CALL CASTARRNUM
            CMP ISERROR, 0
            JG RETURN_ERR_INPUTARR
            INPUT_ARRNUM_CONTINUE:
                MOV AX, ARRNUM
                MOV BX, ARRAY_OFFSET
                MOV ARRAY + BX, AX
                INC ARRAY_OFFSET
                INC ARRAY_OFFSET
                POP CX
            LOOP INPUT_ARRNUM
        RET
        RETURN_ERR_INPUTARR:
            POP CX
            RET       
    INPUTARR ENDP
    
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
    
    CASTFINDNUM PROC NEAR
        MOV FINDNUM, 0
        MOV POSITION, 01H
        MOV CH, 0    
        MOV CL, FINDNUMLEN
        MOV BX, CX
        DEC BX
        LEA SI, FINDNUMFLD
        MOV AX, [SI]
        CMP AL, '-'
        JNE PROCESS_DIGIT_CASTFINDNUM
        DEC CX
        PROCESS_DIGIT_CASTFINDNUM:
            MOV AH, 0
            MOV AL, [SI + BX]
            CMP AL, 030H
            JL RETURNERR_CASTFINDNUM
            CMP AL, 039H
            JG RETURNERR_CASTFINDNUM
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERR_CASTFINDNUM
            ADD FINDNUM, AX
            JNO NEXT_CASTFINDNUM
            CMP FINDNUM, MIN
            JNE RETURNERR_CASTFINDNUM
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURNERR_CASTFINDNUM
            NEXT_CASTFINDNUM:
                DEC BX
                CMP CX, 1
                JE PRERETURN_CASTFINDNUM
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR_CASTFINDNUM
                MOV POSITION, AX
                LOOP PROCESS_DIGIT_CASTFINDNUM
                PRERETURN_CASTFINDNUM:
            MOV AX, [SI]
            CMP AL, '-'
            JNE RETURN_CASTFINDNUM
            NEG FINDNUM
        RETURN_CASTFINDNUM:
            RET
        RETURNERR_CASTFINDNUM:
            CALL PRINTERR
            MOV ISERROR, 01H
            RET
    CASTFINDNUM ENDP
    
    CASTROWS PROC NEAR
        MOV ROWSNUM, 0
        MOV POSITION, 01H
        MOV CH, 0    
        MOV CL, ROWSLEN
        MOV BX, CX
        DEC BX
        LEA SI, ROWSFLD
        MOV AX, [SI]
        CMP AL, '-'
        JE RETURNERR_CASTROWS
        PROCESS_DIGIT_CASTROWS:
            MOV AH, 0
            MOV AL, [SI + BX]
            CMP AL, 030H
            JL RETURNERR_CASTROWS
            CMP AL, 039H
            JG RETURNERR_CASTROWS
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERR_CASTROWS
            ADD ROWSNUM, AX
            JO RETURNERR_CASTROWS
            CMP ROWSNUM, 0AH
            JG RETURNERR_CASTROWS
            NEXT_CASTROWS:
                DEC BX
                CMP CX, 1
                JE RETURN_CASTROWS
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR_CASTROWS
                MOV POSITION, AX
                LOOP PROCESS_DIGIT_CASTROWS
        RETURN_CASTROWS:
            CMP ROWSNUM, 0
            JLE RETURNERR_CASTROWS
            RET
            RETURNERR_CASTROWS:
            CALL PRINTERR
            MOV ISERROR, 01H
            RET
    CASTROWS ENDP
    
    CASTCOLS PROC NEAR
        MOV COLSNUM, 0
        MOV POSITION, 01H
        MOV CH, 0    
        MOV CL, COLSLEN
        MOV BX, CX
        DEC BX
        LEA SI, COLSFLD
        MOV AX, [SI]
        CMP AL, '-'
        JE RETURNERR_CASTCOLS
        PROCESS_DIGIT_CASTCOLS:
            MOV AH, 0
            MOV AL, [SI + BX]
            CMP AL, 030H
            JL RETURNERR_CASTCOLS
            CMP AL, 039H
            JG RETURNERR_CASTCOLS
            SUB AL, 030H
            IMUL POSITION
            JO RETURNERR_CASTCOLS
            ADD COLSNUM, AX
            JO RETURNERR_CASTCOLS
            CMP COLSNUM, 0AH
            JG RETURNERR_CASTCOLS
            NEXT_CASTCOLS:
                DEC BX
                CMP CX, 1
                JE RETURN_CASTCOLS
                MOV AX, POSITION
                IMUL NUMRADIX
                JO RETURNERR_CASTCOLS
                MOV POSITION, AX
                LOOP PROCESS_DIGIT_CASTCOLS
        RETURN_CASTCOLS:
            CMP COLSNUM, 0
            JLE RETURNERR_CASTCOLS
            RET
            RETURNERR_CASTCOLS:
            CALL PRINTERR
            MOV ISERROR, 01H
            RET
    CASTCOLS ENDP
    
    PRINTINCLUSIONS PROC NEAR
        MOV AH, 09H
        LEA DX, INCLUSIONSMSG
        INT 021H 
        CALL NEWLINE
        
        MOV ARRAY_OFFSET, 0
        MOV CX, ROWSNUM
        CHECK_ROWS:
            PUSH CX
            MOV AX, ROWSNUM
            SUB AX, CX
            MOV ARRAYI, AX
            IMUL COLSNUM
            IMUL ARRNUM_SIZE
            MOV ARRAY_OFFSET, AX
            MOV CX, COLSNUM
            CHECK_ROW:
                PUSH CX
                MOV AX, COLSNUM
                SUB AX, CX
                MOV ARRAYJ, AX
                MOV BX, ARRAY_OFFSET
                MOV AX, ARRAY + BX
                CMP AX, FINDNUM
                JNE CHECK_ROW_CONTINUE
                MOV ISNUMFOUND, 1
                CALL PRINTARRINDEXES
                CHECK_ROW_CONTINUE:
                    INC ARRAY_OFFSET
                    INC ARRAY_OFFSET
                    POP CX
                    LOOP CHECK_ROW
            POP CX
            LOOP CHECK_ROWS
        CMP ISNUMFOUND, 1
        JE PRINTINCLUSIONS_RETURN
        MOV AH, 09H
        LEA DX, NOTFOUNDMSG
        INT 021H 
        CALL NEWLINE
        PRINTINCLUSIONS_RETURN:
            RET
    PRINTINCLUSIONS ENDP
    
    PRINTARRINDEXES PROC NEAR
        MOV CHAR, '['
        CALL PRINTCHAR
        CALL PRINTROWINDEX
        MOV CHAR, ','
        CALL PRINTCHAR
        CALL PRINTCOLINDEX
        MOV CHAR, ']'
        CALL PRINTCHAR
        CALL NEWLINE
        RET
    PRINTARRINDEXES ENDP
    
    PRINTARR PROC NEAR
        MOV AH, 09H
        LEA DX, PRINTARRAYMSG
        INT 021H 
        CALL NEWLINE
    
        MOV ARRAY_OFFSET, 0
        MOV CX, ROWSNUM
        PRINT_ROWS:
            PUSH CX
            MOV AX, ROWSNUM
            SUB AX, CX
            IMUL COLSNUM
            IMUL ARRNUM_SIZE
            MOV ARRAY_OFFSET, AX
            MOV CX, COLSNUM
            PRINT_ROW:
                PUSH CX
                MOV BX, ARRAY_OFFSET
                MOV AX, ARRAY + BX
                MOV ARRNUM, AX
                CALL PRINTARRNUM
                
                MOV DL, 020H
                MOV AH, 02H
                INT 21H     
                
                INC ARRAY_OFFSET
                INC ARRAY_OFFSET
                POP CX
                LOOP PRINT_ROW
        CALL NEWLINE
        POP CX
        LOOP PRINT_ROWS
        RET
    PRINTARR ENDP
    
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
    
    PRINTROWINDEX PROC NEAR
        CMP ARRAYI, 0
        JGE M1_PRINTROWINDEX
        MOV AL, '-'
        INT 29H
        NEG ARRAYI
        M1_PRINTROWINDEX:
            MOV CX, 0
            MOV BX, 0AH
            MOV DX, 0
            MOV AX, ARRAYI
        M2_PRINTROWINDEX:
            IDIV BX
            OR DL, 030H
            PUSH DX
            INC CX
            MOV DX, 0
            TEST AX, AX
            JNZ M2_PRINTROWINDEX
        M3_PRINTROWINDEX:
            POP AX
            INT 029H
            LOOP M3_PRINTROWINDEX
        RET
    PRINTROWINDEX ENDP

    PRINTCOLINDEX PROC NEAR
        CMP ARRAYJ, 0
        JGE M1_PRINTCOLINDEX
        MOV AL, '-'
        INT 29H
        NEG ARRAYJ
        M1_PRINTCOLINDEX:
            MOV CX, 0
            MOV BX, 0AH
            MOV DX, 0
            MOV AX, ARRAYJ
        M2_PRINTCOLINDEX:
            IDIV BX
            OR DL, 030H
            PUSH DX
            INC CX
            MOV DX, 0
            TEST AX, AX
            JNZ M2_PRINTCOLINDEX
            M3_PRINTCOLINDEX:
            POP AX
            INT 029H
            LOOP M3_PRINTCOLINDEX
        RET
    PRINTCOLINDEX ENDP
    
    PRINTCHAR PROC NEAR
        MOV DL, CHAR
        MOV AH, 02H
        INT 21H
        RET
    PRINTCHAR ENDP
    
    NEWLINE PROC NEAR
        MOV CHAR, CR
        CALL PRINTCHAR
        MOV CHAR, LF
        CALL PRINTCHAR 
        RET
    NEWLINE ENDP
    
    PRINTERR PROC NEAR
        MOV AH, 09H
        LEA DX, ERRORMSG
        INT 021H 
        CALL NEWLINE
        RET
    PRINTERR ENDP
CSEG ENDS
END BEGIN