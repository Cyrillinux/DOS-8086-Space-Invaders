@echo off
set TASM_OPTIONS=/mx /zi /dMDL=small /m
tasm %TASM_OPTIONS% SPACE92
rem tlink SPACE92,,,libpps+libmem
tlink SPACE92,,,libpps
copy SPACE92.exe ..
cd ..
