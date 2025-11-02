cmake_minimum_required(VERSION 3.10)
project(${p})

add_custom_target(run
    DEPENDS ${s}.asm
    COMMAND nasm -f elf64 ../${s}.asm -o ${s}.o -l listing.lst
    COMMAND ld -o ${o} ${s}.o
    COMMAND strace -o log.txt ./${o}
)