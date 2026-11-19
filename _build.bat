:: This is deprecated for now, just so I can call make for both Windows and Linux
@echo off

if not exist build (mkdir build)

pushd build

set code_dir=..\code\

nasm -i%code_dir% %code_dir%booty0.asm -f bin -o booty0.bin
nasm -i%code_dir% %code_dir%booty1.asm -f bin -o booty1.bin
cat booty0.bin booty1.bin > main.bin
cp main.bin main.img
truncate -s 1440k main.img

popd
