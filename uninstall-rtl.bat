@echo off
setlocal EnableExtensions
title RTL Chat for ZCode - uninstaller
cd /d "%~dp0"

set "NOPAUSE="
if /I "%~1"=="--no-pause" set "NOPAUSE=1"

set "ASAR="
if exist "%LOCALAPPDATA%\Programs\ZCode\resources\app.asar" set "ASAR=%LOCALAPPDATA%\Programs\ZCode\resources\app.asar"
if not defined ASAR if exist "%ProgramFiles%\ZCode\resources\app.asar" set "ASAR=%ProgramFiles%\ZCode\resources\app.asar"
if not defined ASAR if exist "%ProgramFiles(x86)%\ZCode\resources\app.asar" set "ASAR=%ProgramFiles(x86)%\ZCode\resources\app.asar"
if not defined ASAR (
  echo [ERROR] ZCode installation not found on this machine.
  goto end
)
echo Found ZCode: %ASAR%

set "BAK=%~dp0asar-work\app.asar.bak"
if not exist "%BAK%" (
  echo [ERROR] No backup found at "%BAK%".
  echo The backup is created on the first install-rtl.bat run. Without it,
  echo reinstall the same ZCode version to get a pristine app.asar back.
  goto end
)

rem --- close ZCode if running, so the asar can be written
"%SystemRoot%\System32\tasklist.exe" /FI "IMAGENAME eq ZCode.exe" 2>nul | "%SystemRoot%\System32\findstr.exe" /I "ZCode.exe" >nul
if errorlevel 1 goto notrunning
echo ZCode is running - closing it so the original file can be restored...
"%SystemRoot%\System32\taskkill.exe" /IM ZCode.exe >nul 2>&1
set /a TRIES=0
:waitclose
"%SystemRoot%\System32\ping.exe" -n 2 127.0.0.1 >nul
"%SystemRoot%\System32\tasklist.exe" /FI "IMAGENAME eq ZCode.exe" 2>nul | "%SystemRoot%\System32\findstr.exe" /I "ZCode.exe" >nul
if errorlevel 1 goto notrunning
set /a TRIES+=1
if %TRIES% lss 5 goto waitclose
echo ZCode minimized to tray instead of quitting - forcing close...
"%SystemRoot%\System32\taskkill.exe" /F /IM ZCode.exe >nul 2>&1
"%SystemRoot%\System32\ping.exe" -n 3 127.0.0.1 >nul
"%SystemRoot%\System32\tasklist.exe" /FI "IMAGENAME eq ZCode.exe" 2>nul | "%SystemRoot%\System32\findstr.exe" /I "ZCode.exe" >nul
if errorlevel 1 goto notrunning
echo [ERROR] ZCode did not close. Quit it manually from the tray icon, then run this file again.
goto end
:notrunning

rem --- ask for admin rights only when ZCode lives in Program Files
echo "%ASAR%" | "%SystemRoot%\System32\findstr.exe" /I /C:"Program Files" >nul
if errorlevel 1 goto restore
"%SystemRoot%\System32\net.exe" session >nul 2>&1
if not errorlevel 1 goto restore
echo Requesting administrator rights - click Yes on the UAC prompt...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '%*'"
exit /b
:restore

copy /Y "%BAK%" "%ASAR%" >nul
if errorlevel 1 (
  echo [ERROR] Restore failed. Right-click this file and "Run as administrator", then retry.
  goto end
)
echo.
echo Done. The original app.asar is restored - RTL patch removed.
echo Open ZCode normally. To patch again later, double-click install-rtl.bat.

:end
if defined NOPAUSE exit /b
echo.
pause