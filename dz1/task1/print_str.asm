global _start                                               ; делаем метку _start видимой извне

section .data                                               ; секция данных
    message db "Hello! How are you?",10                     ; строка для вывода на консоль
    length equ $ - message

    error_msg db "Write failed!",10                         ; сообщение об ошибке
    error_len equ $ - error_msg

    partial_msg db "Partial write (ERROR)",10               ; сообщение о чистичной записи
    partial_len equ $ - partial_msg

section .text                                   ; объявление секции кода
_start:                                         ; точка входа в программу
    mov rax, 1                                  ; 1 - номер системного вызова функции write
    mov rdi, 1                                  ; 1 - дескриптор файла стандартного вызова stdout
    mov rsi, message                            ; адрес строки для вывода
    mov rdx, length                             ; количество байтов
    syscall                                     ; выполняем системный вызов write
    
    cmp rax, 0                                  ; сравниваем с 0
    jl write_failed                             ; если < 0 - ошибка системного вызова
    jz write_failed                             ; если = 0 - ничего не вывелось
    cmp rax, length                             ; сравниваем с ожидаемой длиной
    jne partial_write                           ; если не равно - частичная запись
    
    mov rax, 60                                 ; sys_exit
    mov rdi, 0                                  ; код возврата 0
    syscall

write_failed:
    mov rax, 1                                  ; sys_write
    mov rdi, 2                                  ; stderr
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    
    mov rax, 60                                 ; sys_exit
    mov rdi, 1                                  ; код ошибки
    syscall

partial_write:
    mov rax, 1                                  
    mov rdi, 2                                 
    mov rsi, partial_msg
    mov rdx, partial_len
    syscall

    mov rax, 60                                 ; sys_exit
    mov rdi, 2                                  ; код возврата 2 - частичная запись
    syscall