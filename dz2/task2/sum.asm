global _start

section .data
    ; Сообщения
    prompt1 db "Enter 1st number: ", 0
    prompt2 db "Enter 2nd number: ", 0
    result_msg db "Sum: ", 0
    newline db 10, 0
    
    ; Сообщения об ошибках
    error_input db "Error: Invalid input format!", 10, 0
    error_range db "Error: Number out of range!", 10, 0
    error_overflow db "Error: Arithmetic overflow!", 10, 0
    error_io db "Error: Input/output error!", 10, 0
    
    ; Константы для проверки диапазона
    MIN_NUMBER equ -32767
    MAX_NUMBER equ 32768

section .bss
    ; Резервирование переменных
    num1 resd 1
    num2 resd 1
    result resd 1
    input_buffer resb 32
    temp_buffer resb 32

section .text
_start:
    ; Вывод для первого числа
    mov rsi, prompt1
    call print_string
    jc exit_error_io
    
    ; Ввод и проверка первого числа
    call read_number
    jc exit_error
    mov [num1], eax
    
    ; Проверка диапазона первого числа
    call check_range
    jc exit_error_range
    
    ; Вывод для второго числа
    mov rsi, prompt2
    call print_string
    jc exit_error_io
    
    ; Ввод и проверка второго числа
    call read_number
    jc exit_error
    mov [num2], eax
    
    ; Проверка диапазона второго числа
    call check_range
    jc exit_error_range
    
    ; Сложение чисел с проверкой переполнения
    mov eax, [num1]
    mov ebx, [num2]
    call sum
    jc exit_error_overflow
    mov [result], eax
    
    ; Вывод результата
    mov rsi, result_msg
    call print_string
    jc exit_error_io
    
    mov eax, [result]
    call print_number
    jc exit_error_io
    
    mov rsi, newline
    call print_string
    jc exit_error_io
    
    ; Успешное завершение
    mov rax, 60
    xor rdi, rdi
    syscall

; Ошибк: неправильный формат ввода
exit_error:
    mov rsi, error_input
    call print_string
    mov rax, 60
    mov rdi, 1
    syscall

; Ошибка: выход за диапазон
exit_error_range:
    mov rsi, error_range
    call print_string
    mov rax, 60
    mov rdi, 2
    syscall

; Ошибка: переполнение
exit_error_overflow:
    mov rsi, error_overflow
    call print_string
    mov rax, 60
    mov rdi, 3
    syscall

; Ошибка:  
exit_error_io:
    mov rsi, error_io
    call print_string
    mov rax, 60
    mov rdi, 5
    syscall

; Сложение
sum:
    push rbx
    push rcx
    push rdx
    
    ; Проверка сложения положительных чисел
    test eax, eax
    js .check_negative
    test ebx, ebx
    js .different_signs
    
    ; Оба положительные
    mov ecx, eax
    add ecx, ebx
    jc .overflow
    
    ; Проверка верхней границы
    cmp ecx, MAX_NUMBER
    jg .overflow
    jmp .success

.check_negative:
    test ebx, ebx
    jns .different_signs
    
    ; Оба отрицательные
    mov ecx, eax
    add ecx, ebx
    jnc .overflow
    
    ; Проверка нижней границы
    cmp ecx, MIN_NUMBER
    jl .overflow
    jmp .success

.different_signs:
    ; Разные знаки - переполнение невозможно
    add eax, ebx
    clc
    jmp .done

.overflow:
    stc
    jmp .done

.success:
    mov eax, ecx
    clc

.done:
    pop rdx
    pop rcx
    pop rbx
    ret

; Проверка диапазона
check_range:
    cmp eax, MIN_NUMBER
    jl .out_of_range
    cmp eax, MAX_NUMBER
    jg .out_of_range
    clc
    ret
.out_of_range:
    stc
    ret

; Чтение числа
read_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Чтение строки
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, input_buffer
    mov rdx, 32
    syscall
    
    ; Проверка успешности чтения
    test rax, rax
    jz .error
    cmp rax, 32
    je .error           ; Буфер переполнен
    
    ; Добавляем нулевой терминатор
    mov rsi, input_buffer
    mov byte [rsi + rax], 0
    
    ; Пропускаем ведущие пробелы
.skip_spaces:
    mov al, [rsi]
    test al, al
    jz .error
    cmp al, ' '
    jne .check_sign
    inc rsi
    jmp .skip_spaces

.check_sign:
    ; Инициализация
    xor eax, eax        ; результат
    xor ebx, ebx        ; флаг знака (0 = положительное)
    xor ecx, ecx        ; счетчик цифр
    xor edx, edx        ; для умножения
    
    ; Проверка знака
    mov al, [rsi]
    cmp al, '-'
    jne .check_plus
    inc ebx             ; устанавливаем флаг отрицательного
    inc rsi
    jmp .read_digits

.check_plus:
    cmp al, '+'
    jne .read_digits
    inc rsi

.read_digits:
    ; Проверка что есть хотя бы одна цифра
    mov al, [rsi]
    cmp al, '0'
    jne .digit_loop
    mov al, [rsi + 1]
    cmp al, '0'
    jb .digit_loop      ; следующий символ не цифра - OK
    cmp al, '9'
    ja .digit_loop      ; следующий символ не цифра - OK
    jmp .error          ; Обнаружены ведущие нули!
    
.digit_loop:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, 10          ; новая строка
    je .done
    cmp al, '0'
    jb .error
    cmp al, '9'
    ja .error
    
    ; Преобразование цифры
    sub al, '0'
    movzx edx, al
    
    ; Проверка на переполнение перед умножением на 10
    mov eax, ecx
    cmp eax, 214748364  ; MAX_INT / 10
    ja .error_range
    imul eax, 10
    jo .error_range
    
    ; Добавление цифры
    add eax, edx
    jo .error_range
    mov ecx, eax
    
    inc rsi
    jmp .digit_loop

.done:
    ; Проверка что было хотя бы одна цифра
    test ecx, ecx
    jz .error
    
    ; Применение знака
    mov eax, ecx
    test ebx, ebx
    jz .positive
    neg eax
    jo .error_range

.positive:
    ; Успешное завершение
    clc
    jmp .exit

.error_range:
    stc
    jmp .exit

.error:
    stc

.exit:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; вывод строки
print_string:
    push rax
    push rdi
    push rdx
    push rcx
    push rsi
    
    ; Вычисление длины строки
    mov rdi, rsi
    xor rcx, rcx
    not rcx
    xor al, al
    cld
    repne scasb
    not rcx
    dec rcx
    jz .empty_string
    
    ; Вывод строки
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rdx, rcx        ; длина
    syscall
    
    ; Проверка успешности
    cmp rax, rdx
    jne .io_error
    clc
    jmp .done

.empty_string:
    clc
    jmp .done

.io_error:
    stc

.done:
    pop rsi
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; Вывод числа
print_number:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov esi, eax        ; сохраняем число
    lea rdi, [temp_buffer + 31] ; конец буфера
    mov byte [rdi], 0   ; нулевой терминатор
    mov ebx, 10
    
    ; Проверка на ноль
    test esi, esi
    jnz .not_zero
    dec rdi
    mov byte [rdi], '0'
    jmp .print

.not_zero:
    ; Проверка знака
    mov ecx, 0          ; флаг отрицательного числа
    test esi, esi
    jns .convert
    neg esi
    mov ecx, 1

.convert:
    dec rdi
    xor edx, edx
    mov eax, esi
    div ebx
    mov esi, eax
    add dl, '0'
    mov [rdi], dl
    test esi, esi
    jnz .convert
    
    ; Добавляем знак минус если нужно
    test ecx, ecx
    jz .print
    dec rdi
    mov byte [rdi], '-'

.print:
    ; Вычисляем длину
    mov rsi, rdi
    lea rdx, [temp_buffer + 32]
    sub rdx, rdi
    
    ; Вывод числа
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    
    ; Проверка успешности
    cmp rax, rdx
    jne .io_error
    clc
    jmp .done

.io_error:
    stc

.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret