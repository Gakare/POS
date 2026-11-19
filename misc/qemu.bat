@echo off
pushd build
cmd /C "C:\Program Files\qemu\qemu-system-x86_64.exe" -drive format=raw,file=main.img
popd