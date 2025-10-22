cmake_minimum_required(VERSION 3.10)
project(Task1)

add_custom_target(run
    DEPENDS main.asm
    COMMAND nasm -f elf64 ../main.asm -o main.o -l listing.lst
    COMMAND ld -o main main.o
    COMMAND strace -o log.txt ./main
)