.386							 ; Директива для использования набора операций процессора 80386
.MODEL  FLAT, STDCALL			 ; Определяем модель памяти
EXTERN  GetStdHandle@4    :	PROC ; Получение дескриптора.
EXTERN  WriteConsoleA@20  :	PROC ; Вывод в консоль.
EXTERN  CharToOemA@8      :	PROC ; Строку в OEM кодировку.
EXTERN  ReadConsoleA@20   :	PROC ; Ввод с консоли.
EXTERN  ExitProcess@4     :	PROC ; Функция выхода из программы.
EXTERN  lstrlenA@4        : PROC ; Функция определения длины строки.

.DATA							 ; Директива определяет начало сегмента данных (данные, которые имеют начальное значение)
	STR_F DB "Введите первое число, а затем второе: ", 10, 0
								 ; "10" - переход на новую строку, "0" - завершение строки
								 ; Директива DB - тип данных хранящий 1 байт
	STR_Sec DB "Результат вычитания в шестнадцатеричной системе: ", 0
	STR_ERR DB "Ошибка. Некорректный ввод. Проверьте корректность вводимых данных.", 0	
								
								; Директива DD - тип данных хранящий 1 DWORD, то есть 4 байта
								; Знак "?" используется для неинициализированных данных
	DIN		DD ?				; Дескриптор ввода
	DOUT	DD ?				; Дескриптор вывода
	BUF		DB 200 dup (?)		; Буфер для строк длиной 200 байт
	LENS	DD ?				; Для количества выведенных символов
	FIRST	DD 0				; Первое число
	SECOND	DD 0				; Второе число
	S_16	DD 16				; Основание системы счисления
	F_SIGN	DB 0				; Флаги для определения знака (F -первое число, S - второе)
	S_SIGN	DB 0				
	SIGN    DB 0


.CODE							; Директива определяет начало сегмента кода
	MAIN proc					; MAIN - название процедуры, директива proc - описывает процедуру
								; Регистр EAX - служит для временного хранения данных
	; Перекодировка STR_F
	LEA EAX, STR_F
	PUSH EAX						
	PUSH EAX
	CALL CharToOemA@8			

	; Перекодировка STR_Sec
	LEA EAX, STR_Sec
	PUSH EAX
	PUSH EAX
	CALL CharToOemA@8

	; Перекодировка STR_ERR
	LEA EAX, STR_ERR
	PUSH EAX
	PUSH EAX
	CALL CharToOemA@8

	; Помещаем дескриптор ввода в DIN
	PUSH -10						
	CALL GetStdHandle@4 
	MOV DIN, EAX

	; Помещаем дескриптор вывода в DOUT
	PUSH -11
	CALL GetStdHandle@4
	MOV DOUT, EAX

	; Выводим строку на экран консоли
	PUSH OFFSET STR_F
	CALL lstrlenA@4			; Помещаем в EAX количество символов в строке STR_F.
	PUSH 0					; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	PUSH EAX				; Помещаем 3-й аргумент в стек (количество символов в строке).
	PUSH OFFSET STR_F		; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	PUSH DOUT				; Помещаем 1-й аргумент в стек (дескриптор вывода).
	CALL WriteConsoleA@20

	; Ввод первого числа.
	PUSH 0					; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количества символов). 
	PUSH 200				; Помещаем 3-й аргумент в стек (максимальное количество символов).
	PUSH OFFSET BUF			; Помещаем 2-й аргумент в стек (адрес начала строки для ввода).
	PUSH DIN				; Помещаем 1-й аргумент в стек (дескриптор ввода).
	CALL ReadConsoleA@20			

	; Перевод из строки в первое число, а также проверка.
	PUSH OFFSET BUF
	SUB LENS, 2				; Определяем длину строки без управляющих символов.
    CMP LENS, 3				; Число должно содержать не меньше 3 знаков.
	JB ERROR
	CMP LENS, 8				; Число должно содержать не больше 8 знаков.
	JA ERROR
	MOV ECX, LENS			; Регистр EСX служит для временного хранения адреса некоторой области данных и используется как счетчик.
	MOV ESI, OFFSET BUF
	XOR EBX, EBX			; Регистр EBX служит для хранения адреса некоторой области данных, а также является вычислительным регистром.
	XOR EAX, EAX

	; Проверяем, отрицательно ли первое число.
	MOV BL, [ESI]
	CMP BL, '-'
	JNE CONVERT_F			; Если не минус, то переход сразу к конвертированию.
	SUB LENS, 1				; Если минус, то уменьшить длину строки на 1.
	MOV ECX, LENS 
	MOV F_SIGN, 1			; Установить флаг отрицательности на 1 (true).
	INC ESI					; Переход на следующий символ строки (цифру).

	; продолжаем перевод
	CONVERT_F:				
	MOV BL,[ESI]			; сначала проверим что символ >= '0'
	CMP BL,'0'
	JAE NEXT				; если символ >='0' то идем дальше
	JMP ERROR
	NEXT:	
	CMP BL,'9'
	JBE NEXT1				; если символ <='9' то обрабатываем
	JMP ERROR
	NEXT1:
	SUB BL, '0'				; вычитаем '0' чтобы получить число
	MOV EDX, 10 
	MUL EDX  
	ADD EAX, EBX 
	INC ESI 
	LOOP CONVERT_F
	MOV FIRST, EAX			; получаем первое число в 10-ной сс.

	; Ввод второго числа.
	PUSH 0			
	PUSH OFFSET LENS				
	PUSH 200						
	PUSH OFFSET BUF					
	PUSH DIN						
	CALL ReadConsoleA@20	

	; Перевод из строки во второе число и проверка.
	PUSH OFFSET BUF
	SUB LENS, 2				; Определяем длину строки без управляющих символов.
    CMP LENS, 3				; Число должно содержать не меньше 3 знаков.
	JB ERROR
	CMP LENS, 8				; Число должно содержать не больше 8 знаков.
	JA ERROR
	MOV ECX, LENS			; Сохраняем длину строки
	MOV ESI, OFFSET BUF		; Храним начало строки в буфере
	XOR EBX, EBX			; Обнуляем регистры
	XOR EAX, EAX			

	; Проверяем, отрицательно ли второе число.
	MOV BL, [ESI]						
	CMP BL, '-'
	JNE CONVERT_S		; Если не минус, то переход сразу к конвертированию.
	SUB LENS, 1		    ; Если минус, то уменьшить длину строки на 1.
	MOV ECX, LENS 
	MOV S_SIGN, 1	    ; Установить флаг отрицательности на 1 (true).
	INC ESI				; Переход на следующий символ строки (цифру).

	; продолжаем перевод
	CONVERT_S:				
	MOV BL,[ESI];сначала проверим что символ >= '0'
	CMP BL,'0'
	JAE NEXT_				; если символ >='0' то идем дальше
	JMP ERROR
	NEXT_:	
	CMP BL,'9'
	JBE NEXT_1				; если символ <='9' то обрабатываем
	JMP ERROR
	NEXT_1:
	SUB BL, '0'				; вычитаем '0' чтобы получить число
	MOV EDX, 10 
	MUL EDX  
	ADD EAX, EBX 
	INC ESI 
	LOOP CONVERT_S
	MOV SECOND, EAX

	XOR EAX, EAX		; Обнуляем регистры
	XOR EBX, EBX
	MOV EAX, FIRST		; Записывыаем числа в регистры
	MOV EBX, SECOND
	CMP EAX, EBX		; Сравнивем два числа
	JNB CONT			; Если первое число больше или равно, продолжаем, иначе меняем местами со вторым

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
	CMP F_SIGN, 0		; Если знак первого числа + продолжаем
	JNE FS_1
	CMP S_SIGN, 0		; Если знак второго + продолжаем, иначе прыгаем в
	JNE FSS_01			; условие: первое число положительное, второе отрицательное
	SUB FIRST, EBX
	JMP RES

	FS_1:
	CMP S_SIGN, 0		; Если знак первого числа -, а второго + продолжаем
	JNE FSS_11			
	ADD FIRST, EBX
	CMP SIGN, 0
	JNE CHANGE_S
	MOV SIGN, 1
	JMP RES

	FSS_01:				; Знак первого +, второго -
	ADD FIRST, EBX
	JMP RES

	FSS_11:				; Знак первого -, второго - 
	SUB FIRST, EBX
	CMP SIGN, 0
	JNE CHANGE_S
	MOV SIGN, 1
	JMP RES

	CHANGE_S:
	MOV SIGN, 0

	RES:
	; преобразование результата
	MOV EDX, FIRST
	XOR EDI, EDI 
	XOR EAX, EAX
	XOR ECX, ECX
	MOV ECX, 2	
	MOV ESI, OFFSET BUF		; начало строки хранится в переменной буфере

	CMP SIGN, 0				; Если результат отрицательный, 
	JE FUNC					; то добавить в строку знак '-'.
	MOV AX, 45				; 45 - код знака '-'.
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
			PUSH EDX		; кладем данные в стек, для инвертирования
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
		PUSH EAX			; кладем данные в стек, для инвертирования
		ADD EDI, 1
		MOV ECX, EDI
		CONVERTS:
			POP [ESI]
			INC ESI
		LOOP CONVERTS

	; выводим результат
	PUSH OFFSET STR_Sec
	CALL lstrlenA@4			; Помещаем в EAX количество символов в строке STR_F.
	PUSH 0					; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	PUSH EAX				; Помещаем 3-й аргумент в стек (количество символов в строке).
	PUSH OFFSET STR_Sec		; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	PUSH DOUT				; Помещаем 1-й аргумент в стек (дескриптор вывода).
	CALL WriteConsoleA@20

	PUSH OFFSET BUF
	CALL lstrlenA@4			; Помещаем в EAX количество символов в строке STR_F.
	PUSH 0					; Помещаем 5-й аргумент в стек (резерв).
	PUSH OFFSET LENS		; Помещаем 4-й аргумент в стек (адрес переменной для количиства символов).
	PUSH EAX				; Помещаем 3-й аргумент в стек (количество символов в строке).
	PUSH OFFSET BUF			; Помещаем 2-й аргумент в стек (адрес начала строки для вывода).
	PUSH DOUT				; Помещаем 1-й аргумент в стек (дескриптор вывода).
	CALL WriteConsoleA@20
	
	; выход из программы 
	PUSH 0				 ; параметр: код выхода
	CALL ExitProcess@4

	; В случае ошибки.
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
		CALL ExitProcess@4 ; выход

	MAIN ENDP				; Директива ENPD завершает описание процедуры
	END MAIN				; Директива END завершает программу, MAIN - имя первой выполняемой процедуры
