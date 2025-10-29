global _start                           ; делаем метку _start видимой извне

section .bss
    buffer resb 1000                    ; резервируем память под строку

section .data
    newLine db 10                       ; символ переноса строки

section .text
reverse_string:
    lea rdi, [buffer + rcx - 1]         ; вычисляем длину строки
.reverse_loop:
    cmp rsi, rdi                        ; сравниваем rsi, rdi
    jge .done                           ; если rsi >= rdi - "прыгаем" на метку .done

    mov al, [rsi]                       ; al - младший байт rax. В al кладём *rsi
    mov bl, [rdi]                       ; bl - младший байт rbx. В bl кладём *rdi
    mov [rsi], bl                       ; в *rsi кладём bl
    mov [rdi], al                       ; в *rdi кладём al

    inc rsi                             ; увеличиваем rsi
    dec rdi                             ; уменьшаем rdi
    jmp .reverse_loop                   ; "прыгаем" на метку .reverse_loop
.done:
    ret                                 ; возвращаемся в _start

_start:
    mov rax, 0                          ; sys_read
    mov rdi, 0                          ; stdin
    mov rsi, buffer                     ; указатель на начало строки
    mov rdx, 1000                       ; максимум байт
    syscall

    mov rcx, rax                        ; счётчик байт в строке
    dec rcx                             ; удаляем '\n'

    mov rsi, buffer                     ; записываем начало строки
    call reverse_string

    mov rax, 1                          ; sys_write
    mov rdi, 1                          ; stdout
    mov rsi, buffer                     ; выводим string
    mov rdx, rcx
    syscall

    mov rax, 1                          ; sys_write
    mov rdi, 1                          ; stdout
    mov rsi, newLine                    ; выводим перенос строки
    mov rdx, 1
    syscall

    mov rax, 60                         ; sys_exit
    mov rdi, 0                          ; ошибок нет
    syscall