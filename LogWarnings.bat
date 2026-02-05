@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~1"=="" (
  echo Usage: extract_warnings.bat ^<path_to_log^>
  exit /b 1
)

set LOG=%~1
if not exist "%LOG%" (
  echo Log not found: %LOG%
  exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set DATE=%%i

set NAME=%~n1
set DIR=%~dp1
set OUT=%DIR%%NAME%_warnings_%DATE%.log

findstr /R /I /C:"Log.*: Warning" /C:"warning:" "%LOG%" > "%OUT%"

echo %OUT%
