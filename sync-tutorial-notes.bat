@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Copy tutorial worksheet PDFs from Notes into the site folder (Windows).

cd /d "%~dp0"

set "SRC=%~dp0..\..\Notes\User-centred_Design_in_Digital_Media\User-centred_Design_in_Digital_Media\Tutorial\pdf"
set "OUT=%~dp0tutorial-notes"

if not exist "%SRC%\" (
  echo Error: tutorial PDF source not found:
  echo   %SRC%
  exit /b 1
)

if not exist "%OUT%\" mkdir "%OUT%"

del /f /q "%OUT%\*.pdf" >nul 2>&1
copy /y "%SRC%\*.pdf" "%OUT%\" >nul
if errorlevel 1 (
  echo Error: failed to copy tutorial PDFs
  exit /b 1
)

set "COUNT=0"
for %%F in ("%OUT%\*.pdf") do set /a COUNT+=1
echo Synced !COUNT! tutorial PDF(s) -^> %OUT%
exit /b 0
