.386							 ; ��������� ��� ������������� ������ �������� ���������� 80386
.MODEL  FLAT, STDCALL			 ; ���������� ������ ������
EXTERN  GetStdHandle@4    :	PROC ; ��������� �����������.
EXTERN  WriteConsoleA@20  :	PROC ; ����� � �������.
EXTERN  CharToOemA@8      :	PROC ; ������ � OEM ���������.
EXTERN  ReadConsoleA@20   :	PROC ; ���� � �������.
EXTERN  ExitProcess@4     :	PROC ; ������� ������ �� ���������.
EXTERN  lstrlenA@4        : PROC ; ������� ����������� ����� ������.

.DATA							 ; ��������� ���������� ������ �������� ������ (������, ������� ����� ��������� ��������)
	STR_F DB "������� ������ �����, � ����� ������: ", 10, 0
								 ; "10" - ������� �� ����� ������, "0" - ���������� ������
								 ; ��������� DB - ��� ������ �������� 1 ����
	STR_Sec DB "��������� ��������� � ����������������� �������: ", 0
	STR_ERR DB "������. ������������ ����. ��������� ������������ �������� ������.", 0	
								
								; ��������� DD - ��� ������ �������� 1 DWORD, �� ���� 4 �����
								; ���� "?" ������������ ��� �������������������� ������
	DIN		DD ?				; ���������� �����
	DOUT	DD ?				; ���������� ������
	BUF		DB 200 dup (?)		; ����� ��� ����� ������ 200 ����
	LENS	DD ?				; ��� ���������� ���������� ��������
	FIRST	DD 0				; ������ �����
	SECOND	DD 0				; ������ �����
	S_16	DD 16				; ��������� ������� ���������
	F_SIGN	DB 0				; ����� ��� ����������� ����� (F -������ �����, S - ������)
	S_SIGN	DB 0				
	SIGN    DB 0


.CODE							; ��������� ���������� ������ �������� ����
	MAIN proc					; MAIN - �������� ���������, ��������� proc - ��������� ���������
								; ������� EAX - ������ ��� ���������� �������� ������
	; ������������� STR_F
	LEA EAX, STR_F
	PUSH EAX						
	PUSH EAX
	CALL CharToOemA@8			

	; ������������� STR_Sec
	LEA EAX, STR_Sec
	PUSH EAX
	PUSH EAX
	CALL CharToOemA@8

	; ������������� STR_ERR
	LEA EAX, STR_ERR
	PUSH EAX
	PUSH EAX
	CALL CharToOemA@8

	; �������� ���������� ����� � DIN
	PUSH -10						
	CALL GetStdHandle@4 
	MOV DIN, EAX

	; �������� ���������� ������ � DOUT
	PUSH -11
	CALL GetStdHandle@4
	MOV DOUT, EAX

	; ������� ������ �� ����� �������
	PUSH OFFSET STR_F
	CALL lstrlenA@4			; �������� � EAX ���������� �������� � ������ STR_F.
	PUSH 0					; �������� 5-� �������� � ���� (������).
	PUSH OFFSET LENS		; �������� 4-� �������� � ���� (����� ���������� ��� ���������� ��������).
	PUSH EAX				; �������� 3-� �������� � ���� (���������� �������� � ������).
	PUSH OFFSET STR_F		; �������� 2-� �������� � ���� (����� ������ ������ ��� ������).
	PUSH DOUT				; �������� 1-� �������� � ���� (���������� ������).
	CALL WriteConsoleA@20

	; ���� ������� �����.
	PUSH 0					; �������� 5-� �������� � ���� (������).
	PUSH OFFSET LENS		; �������� 4-� �������� � ���� (����� ���������� ��� ���������� ��������). 
	PUSH 200				; �������� 3-� �������� � ���� (������������ ���������� ��������).
	PUSH OFFSET BUF			; �������� 2-� �������� � ���� (����� ������ ������ ��� �����).
	PUSH DIN				; �������� 1-� �������� � ���� (���������� �����).
	CALL ReadConsoleA@20			

	; ������� �� ������ � ������ �����, � ����� ��������.
	PUSH OFFSET BUF
	SUB LENS, 2				; ���������� ����� ������ ��� ����������� ��������.
    CMP LENS, 3				; ����� ������ ��������� �� ������ 3 ������.
	JB ERROR
	CMP LENS, 8				; ����� ������ ��������� �� ������ 8 ������.
	JA ERROR
	MOV ECX, LENS			; ������� E�X ������ ��� ���������� �������� ������ ��������� ������� ������ � ������������ ��� �������.
	MOV ESI, OFFSET BUF
	XOR EBX, EBX			; ������� EBX ������ ��� �������� ������ ��������� ������� ������, � ����� �������� �������������� ���������.
	XOR EAX, EAX

	; ���������, ������������ �� ������ �����.
	MOV BL, [ESI]
	CMP BL, '-'
	JNE CONVERT_F			; ���� �� �����, �� ������� ����� � ���������������.
	SUB LENS, 1				; ���� �����, �� ��������� ����� ������ �� 1.
	MOV ECX, LENS 
	MOV F_SIGN, 1			; ���������� ���� ��������������� �� 1 (true).
	INC ESI					; ������� �� ��������� ������ ������ (�����).

	; ���������� �������
	CONVERT_F:				
	MOV BL,[ESI]			; ������� �������� ��� ������ >= '0'
	CMP BL,'0'
	JAE NEXT				; ���� ������ >='0' �� ���� ������
	JMP ERROR
	NEXT:	
	CMP BL,'9'
	JBE NEXT1				; ���� ������ <='9' �� ������������
	JMP ERROR
	NEXT1:
	SUB BL, '0'				; �������� '0' ����� �������� �����
	MOV EDX, 10 
	MUL EDX  
	ADD EAX, EBX 
	INC ESI 
	LOOP CONVERT_F
	MOV FIRST, EAX			; �������� ������ ����� � 10-��� ��.

	; ���� ������� �����.
	PUSH 0			
	PUSH OFFSET LENS				
	PUSH 200						
	PUSH OFFSET BUF					
	PUSH DIN						
	CALL ReadConsoleA@20	

	; ������� �� ������ �� ������ ����� � ��������.
	PUSH OFFSET BUF
	SUB LENS, 2				; ���������� ����� ������ ��� ����������� ��������.
    CMP LENS, 3				; ����� ������ ��������� �� ������ 3 ������.
	JB ERROR
	CMP LENS, 8				; ����� ������ ��������� �� ������ 8 ������.
	JA ERROR
	MOV ECX, LENS			; ��������� ����� ������
	MOV ESI, OFFSET BUF		; ������ ������ ������ � ������
	XOR EBX, EBX			; �������� ��������
	XOR EAX, EAX			

	; ���������, ������������ �� ������ �����.
	MOV BL, [ESI]						
	CMP BL, '-'
	JNE CONVERT_S		; ���� �� �����, �� ������� ����� � ���������������.
	SUB LENS, 1		    ; ���� �����, �� ��������� ����� ������ �� 1.
	MOV ECX, LENS 
	MOV S_SIGN, 1	    ; ���������� ���� ��������������� �� 1 (true).
	INC ESI				; ������� �� ��������� ������ ������ (�����).

	; ���������� �������
	CONVERT_S:				
	MOV BL,[ESI];������� �������� ��� ������ >= '0'
	CMP BL,'0'
	JAE NEXT_				; ���� ������ >='0' �� ���� ������
	JMP ERROR
	NEXT_:	
	CMP BL,'9'
	JBE NEXT_1				; ���� ������ <='9' �� ������������
	JMP ERROR
	NEXT_1:
	SUB BL, '0'				; �������� '0' ����� �������� �����
	MOV EDX, 10 
	MUL EDX  
	ADD EAX, EBX 
	INC ESI 
	LOOP CONVERT_S
	MOV SECOND, EAX

	XOR EAX, EAX		; �������� ��������
	XOR EBX, EBX
	MOV EAX, FIRST		; ����������� ����� � ��������
	MOV EBX, SECOND
	CMP EAX, EBX		; ��������� ��� �����
	JNB CONT			; ���� ������ ����� ������ ��� �����, ����������, ����� ������ ������� �� ������

	SWAP_F_S:
	MOV SIGN, 1
	MOV FIRST, EBX
	MOV SECOND, EAX
	XOR EDX, EDX
	MOV DL, F_SIGN
	MOV DH, S_SIGN
	MOV F_SIGN, DH
	MOV S_SIGN, DL

	XOR EAX, EAX
	XOR EBX, EBX
	XOR EDX, EDX

	CONT:
	MOV EAX, FIRST
	MOV EBX, SECOND
	CMP F_SIGN, 0		; ���� ���� ������� ����� + ����������
	JNE FS_1
	CMP S_SIGN, 0		; ���� ���� ������� + ����������, ����� ������� �
	JNE FSS_01			; �������: ������ ����� �������������, ������ �������������
	SUB FIRST, EBX
	JMP RES

	FS_1:
	CMP S_SIGN, 0		; ���� ���� ������� ����� -, � ������� + ����������
	JNE FSS_11			
	ADD FIRST, EBX
	CMP SIGN, 0
	JNE CHANGE_S
	MOV SIGN, 1
	JMP RES

	FSS_01:				; ���� ������� +, ������� -
	ADD FIRST, EBX
	JMP RES

	FSS_11:				; ���� ������� -, ������� - 
	SUB FIRST, EBX
	CMP SIGN, 0
	JNE CHANGE_S
	MOV SIGN, 1
	JMP RES

	CHANGE_S:
	MOV SIGN, 0

	RES:
	; �������������� ����������
	MOV EDX, FIRST
	XOR EDI, EDI 
	XOR EAX, EAX
	XOR ECX, ECX
	MOV ECX, 2	
	MOV ESI, OFFSET BUF		; ������ ������ �������� � ���������� ������

	CMP SIGN, 0				; ���� ��������� �������������, 
	JE FUNC					; �� �������� � ������ ���� '-'.
	MOV AX, 45				; 45 - ��� ����� '-'.
	MOV [ESI], AX
	INC ESI

	FUNC:	
	MOV EBX, EDX
	MOV EAX, EBX
	XOR EDX, EDX
	
	CONVERT_FROM10TO16:
		CMP EBX, S_16
		JAE FUNC1
		JB FUNC5
		FUNC1:
			DIV S_16
			ADD DX, '0'
		CMP DX, '9'
		JA FUNC2
		JBE FUNC3
		FUNC2:
			ADD DX, 7
		FUNC3:
			PUSH EDX		; ������ ������ � ����, ��� ��������������
			ADD EDI, 1
			XOR EDX, EDX
			XOR EBX,EBX
			MOV BX, AX
			MOV ECX, 2
	LOOP CONVERT_FROM10TO16
	FUNC5:
		ADD AX, '0'
		CMP AX, '9'
		JAE FUNC6
		JB FUNC7
		FUNC6:
			ADD AX, 7

	FUNC7:
		PUSH EAX			; ������ ������ � ����, ��� ��������������
		ADD EDI, 1
		MOV ECX, EDI
		CONVERTS:
			POP [ESI]
			INC ESI
		LOOP CONVERTS

	; ������� ���������
	PUSH OFFSET STR_Sec
	CALL lstrlenA@4			; �������� � EAX ���������� �������� � ������ STR_F.
	PUSH 0					; �������� 5-� �������� � ���� (������).
	PUSH OFFSET LENS		; �������� 4-� �������� � ���� (����� ���������� ��� ���������� ��������).
	PUSH EAX				; �������� 3-� �������� � ���� (���������� �������� � ������).
	PUSH OFFSET STR_Sec		; �������� 2-� �������� � ���� (����� ������ ������ ��� ������).
	PUSH DOUT				; �������� 1-� �������� � ���� (���������� ������).
	CALL WriteConsoleA@20

	PUSH OFFSET BUF
	CALL lstrlenA@4			; �������� � EAX ���������� �������� � ������ STR_F.
	PUSH 0					; �������� 5-� �������� � ���� (������).
	PUSH OFFSET LENS		; �������� 4-� �������� � ���� (����� ���������� ��� ���������� ��������).
	PUSH EAX				; �������� 3-� �������� � ���� (���������� �������� � ������).
	PUSH OFFSET BUF			; �������� 2-� �������� � ���� (����� ������ ������ ��� ������).
	PUSH DOUT				; �������� 1-� �������� � ���� (���������� ������).
	CALL WriteConsoleA@20
	
	; ����� �� ��������� 
	PUSH 0				 ; ��������: ��� ������
	CALL ExitProcess@4

	; � ������ ������.
	ERROR:
		PUSH OFFSET STR_ERR
		CALL lstrlenA@4
		PUSH 0
		PUSH OFFSET LENS
		PUSH EAX
		PUSH OFFSET STR_ERR
		PUSH DOUT
		CALL WriteConsoleA@20

		PUSH 0
		CALL ExitProcess@4 ; �����

	MAIN ENDP				; ��������� ENPD ��������� �������� ���������
	END MAIN				; ��������� END ��������� ���������, MAIN - ��� ������ ����������� ���������
