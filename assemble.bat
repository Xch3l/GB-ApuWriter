@echo off
setlocal

rem Vars so as not to clog PATH
set wla_cpu=%~d0/bin/wladx/wla-gb
set wlalink=%~d0/bin/wladx/wlalink

rem Get current dir name
for %%D in ("%CD%") do set "dirname=%%~nxD"

if "%1" == "-r" del %dirname%.gb *.lst *.sym >NUL 2>&1

rem Back up previous build
set ROM_VERSION=1

:check
if not exist "old\%dirname%_%ROM_VERSION%.gb" goto :dobackup
set /A ROM_VERSION+=1
goto check

:dobackup
if not exist %dirname%.gb goto run
if not exist "old/" mkdir "old"
move %dirname%.gb "old\%dirname%_%ROM_VERSION%.gb" > NUL

:run
rem Create object file
echo Creating object file...
set /A ROM_VERSION-=1
%wla_cpu% -D ROM_VERSION=%ROM_VERSION% -D _TIME_=" %TIME%" -D _DATE_=" %DATE%" -o %dirname%.o main.asm

rem Stop if that failed
if not "%ERRORLEVEL%" == "0" exit /B %ERRORLEVEL%

rem Generate linker script
echo [objects]>linkfile
echo %dirname%.o>>linkfile

rem Link everything
echo Linking...
%wlalink% -S -v linkfile %dirname%.gb

rem Clean up
del %dirname%.o linkfile

endlocal
