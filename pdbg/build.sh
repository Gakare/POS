#!/bin/bash

code="$PWD"
opts=-g
cd build > /dev/null
g++ $opts $code/code/win32_pdbg.c -o win32_pdbg.exe
cd $code > /dev/null
