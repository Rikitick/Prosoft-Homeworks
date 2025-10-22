global _start

section .data
    filename db "result.txt", 0                 ; имя файла с нулевым байтом
    message db "Hello! How are you?", 10        ; строка для записи
    length equ $ - message                      ; длина строки

section .text
_start:
    mov rax, 2                              ; 2 - sys_open
    mov rdi, filename                       ; имя файла
    mov rsi, 0o1 | 0o100 | 0o400            ; флаги: 0o1 - O_WRONLY (Только запись)
                                            ; | 0o100 - O_CREAT (Создать файл, если нет) 
                                            ; | 0o400 - O_TRUNC (Удалить столько байт (если есть), сколько в строке для записи)
    mov rdx, 0o600                          ; Права: rw------- (Только владелец)
    syscall
    
    cmp rax, 0                              ; сравнение с 0
    jl open_failed                          ; если дескриптор отрицательный - ошибка
    
    mov r8, rax                             ; сохраняем fd в r8
    
    mov rax, 1                              ; 1 - sys_write
    mov rdi, r8                             ; файловый дескриптор
    mov rsi, message                        ; буфер для записи
    mov rdx, length                         ; количество байтов
    syscall
    
    cmp rax, 0
    jl write_failed
    
    mov rax, 3                              ; 3 - sys_close
    mov rdi, r8                             ; файловый дескриптор
    syscall
    
    mov rax, 60                             ; sys_exit
    mov rdi, 0                              ; код возврата 0 - всё норм
    syscall

open_failed:
    mov rax, 60
    mov rdi, 1                              ; код ошибки для open
    syscall

write_failed:
    mov rax, 60
    mov rdi, 2                              ; код ошибки для write
    syscall
