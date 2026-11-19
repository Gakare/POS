@echo off
set opts=-FC -GR- -EHa- -nologo -Zi
set code=%cd%

if not exist build (mkdir build)

pushd build
cl %opts% %code%\code\win32_pdbg.c -Fepdbg.exe /link User32.lib
popd
