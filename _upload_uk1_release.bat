@echo off
REM ============================================================
REM Upload uk1_outboxer.glb as the v1 GitHub Release asset.
REM Needed once. After this runs successfully, the hosted
REM iPad / desktop tools auto-fetch UK1 from the release and
REM cache it in IndexedDB.
REM
REM Usage: double-click this .bat. Requires gh CLI; if it's
REM missing, this script tries to install it via winget and
REM prompts you to sign in once.
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo === VR Boxing Mocap: UK1 release upload ===
echo.

REM 1. Is the GLB next to us?
if not exist "uk1_outboxer.glb" (
  echo ERROR: uk1_outboxer.glb not found in this folder.
  echo        Run _convert_uk1.bat first to produce it.
  pause
  exit /b 1
)

REM 2. Do we have gh?
where gh >nul 2>&1
if %ERRORLEVEL%==0 goto have_gh

echo gh CLI not found. Trying winget install...
where winget >nul 2>&1
if not %ERRORLEVEL%==0 (
  echo.
  echo winget is also unavailable on this machine.
  echo Please upload UK1 manually:
  echo   1. Open https://github.com/sammyvilla8-sketch/vr-boxing-mocap/releases/new
  echo   2. Tag: v1   Title: UK1 Character GLB
  echo   3. Drag uk1_outboxer.glb from this folder into the assets zone
  echo   4. Click "Publish release"
  echo.
  pause
  exit /b 1
)

winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
if not %ERRORLEVEL%==0 (
  echo winget install failed. Falling back to manual upload.
  echo Browser URL: https://github.com/sammyvilla8-sketch/vr-boxing-mocap/releases/new
  pause
  exit /b 1
)

REM PATH may not pick up the new gh in this shell; nudge it.
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\GitHub CLI;%PROGRAMFILES%\GitHub CLI"

:have_gh
echo gh CLI ready.
gh --version

REM 3. Auth?
gh auth status >nul 2>&1
if not %ERRORLEVEL%==0 (
  echo.
  echo You are not signed in to GitHub. Launching browser sign-in...
  gh auth login --web
  if not %ERRORLEVEL%==0 (
    echo Sign-in cancelled or failed. Re-run this script after signing in.
    pause
    exit /b 1
  )
)

REM 4. Create the release (or, if v1 already exists, just upload the asset).
echo.
echo Creating release v1 with uk1_outboxer.glb attached...
gh release view v1 -R sammyvilla8-sketch/vr-boxing-mocap >nul 2>&1
if %ERRORLEVEL%==0 (
  echo Release v1 already exists. Uploading / overwriting asset...
  gh release upload v1 "uk1_outboxer.glb" -R sammyvilla8-sketch/vr-boxing-mocap --clobber
) else (
  gh release create v1 "uk1_outboxer.glb" -R sammyvilla8-sketch/vr-boxing-mocap ^
    --title "UK1 Character GLB" ^
    --notes "UK1 outboxer character (~67MB Draco-compressed). Auto-fetched by index.html and ipad.html on first load, cached in IndexedDB for subsequent visits."
)

if %ERRORLEVEL%==0 (
  echo.
  echo === DONE ===
  echo Release URL: https://github.com/sammyvilla8-sketch/vr-boxing-mocap/releases/tag/v1
  echo Asset URL:   https://github.com/sammyvilla8-sketch/vr-boxing-mocap/releases/download/v1/uk1_outboxer.glb
) else (
  echo.
  echo Upload failed. Check the message above. You can also upload manually at:
  echo https://github.com/sammyvilla8-sketch/vr-boxing-mocap/releases/new
)

echo.
pause
endlocal
