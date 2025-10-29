global _start                                               ; делаем метку _start видимой извне

section .data                                               ; секция данных
    message db "Hello! How are you?",10                     ; строка для вывода на консоль
    length equ $ - message

    error_msg db "Write failed!",10                         ; сообщение об ошибке
    error_len equ $ - error_msg

section .text                                   ; объявление секции кода
_start:                                         ; точка входа в программу
    mov rax, 1                                  ; 1 - номер системного вызова функции write
    mov rdi, 1                                  ; 1 - дескриптор файла стандартного вызова stdout
    mov rsi, message                            ; адрес строки для вывода
    mov rdx, length                             ; количество байтов
    syscall                                     ; выполняем системный вызов write
    
    cmp rax, 0                                  ; сравниваем результат с 0
    jl write_failed                             ; если отрицательное - ошибка

    mov rax, 60                                 ; 60 - номер системного вызова exit
    mov rdi, 0                                  ; код возврата 0 - всё норм
    syscall                                     ; выполняем системный вызов exit

write_failed:
    mov rax, 1                                  ; sys_write
    mov rdi, 2                                  ; stderr
    mov rsi, error_msg
    mov rdx, error_len
    syscall
    
    mov rax, 60                                 ; sys_exit
    mov rdi, 1                                  ; код возврата 1 - ошибка
    syscall