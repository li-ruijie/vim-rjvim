@ECHO OFF
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat"
cl /O2 /LD mod.c user32.lib
move mod.dll mod32.dll

CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
cl /O2 /LD mod.c user32.lib
move mod.dll mod64.dll

DEL *.obj *.exp *.lib
GOTO :EOF
