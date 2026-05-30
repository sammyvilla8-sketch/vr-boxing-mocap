@echo off
REM Launch Chrome on the deployed Pages URL with the Default profile,
REM bypassing the profile picker. Forces a cache-busting query string.
setlocal
set URL=https://sammyvilla8-sketch.github.io/vr-boxing-mocap/?nocache=v2_skel_%RANDOM%

set "CHROME="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" set "CHROME=C:\Program Files\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" set "CHROME=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"

if not defined CHROME (
  echo Could not locate chrome.exe on the standard paths.
  pause
  exit /b 1
)

echo Launching: %CHROME%
echo URL: %URL%
start "" "%CHROME%" --profile-directory="Default" "%URL%"
endlocal
exit /b 0
