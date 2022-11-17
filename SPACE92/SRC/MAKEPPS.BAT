@echo off
set  TASM_OPTIONS=/mx /zi /m
tasm %TASM_OPTIONS% libppsld.asm
tasm %TASM_OPTIONS% libpps.asm
tlib libpps +-libpps.obj +-libppsld.obj
rem copy pps.lib ppslib.lib
rem del  pps.lib
