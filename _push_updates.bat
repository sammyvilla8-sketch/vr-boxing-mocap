@echo off
REM ============================================================
REM Push the split-panel + UK1-release updates to main.
REM Run this AFTER the changes have been made locally.
REM Idempotent: re-run if push fails partway.
REM ============================================================

setlocal
cd /d "%~dp0"

REM Clean any scratch validation files that may be lying around
if exist index_inline.js del /q index_inline.js
if exist ipad_inline.js  del /q ipad_inline.js

echo.
echo === VR Boxing Mocap: push updates ===
echo Folder: %CD%
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] git not on PATH. Install Git for Windows then re-run.
  pause
  exit /b 1
)

REM Confirm we have a working .git here
if not exist .git (
  echo [ERROR] No .git folder. Run _deploy_to_github.bat for a fresh deploy.
  pause
  exit /b 1
)

REM Clean any stale .git/index.lock or tmp objects left behind by a crashed git
if exist ".git\index.lock" (
  echo [step 0] removing stale .git\index.lock
  del /f /q ".git\index.lock"
)
for /r ".git\objects" %%f in (tmp_obj_*) do (
  echo [step 0] removing stale tmp object: %%f
  del /f /q "%%f"
)

git config user.email "sammyvilla8@gmail.com"
git config user.name "sammyvilla8-sketch"

echo [step 1] git add -A
git add -A
git status --short
echo.

echo [step 2] git commit
git commit -m "Layout: corner-overlay camera by default + Popout Camera + Popout 3D" -m "Sammy's feedback: the previous side-by-side split layout made the camera tiny on a 1366px laptop (camera ended up ~212px wide because both panels had to fit inside the center column between two 320/340px control rails). Reverting to the original layout pattern:" -m "DEFAULT: 3D scene fills the full center column. The camera is a draggable+resizable corner overlay (~400x300 on desktop, ~38vw on iPad). Resize by dragging the bottom-right corner of the overlay." -m "OPTIONAL toggles in the top-right of the 3D panel (desktop has a key for each):" -m "- 'Split' (V key) — switches to a real side-by-side panel layout (35/65). Use when you want the camera at fixed proportions." -m "- 'Big 3D' (B key) — shrinks the corner overlay to ~200px so the character fills almost the whole panel." -m "- 'Popout Cam' (C key, desktop only) — opens the camera in its own browser window so you can drag it to a second monitor. Mirrors the opener's MediaStream + landmark overlay canvas; no re-permission needed." -m "- 'Popout 3D' (P key, desktop only) — opens the 3D scene in its own window (existing feature)." -m "Big 3D and Split are mutually exclusive. iPad omits the popouts (iOS Safari doesn't support multi-window)."
if errorlevel 1 (
  echo [info] Nothing to commit, or commit failed. Checking remote anyway...
)

echo.
echo [step 3] git push origin main
git push origin main
if errorlevel 1 (
  echo.
  echo [ERROR] push failed. If it's an auth issue, run:
  echo   git config --global credential.helper manager
  echo Then re-run this script. Or push manually:
  echo   git push origin main
  pause
  exit /b 1
)

echo.
echo ===============================================================
echo  PUSHED.
echo  Desktop: https://sammyvilla8-sketch.github.io/vr-boxing-mocap/
echo  iPad:    https://sammyvilla8-sketch.github.io/vr-boxing-mocap/ipad.html
echo  Pages auto-rebuilds on push; takes 1-3 min.
echo ===============================================================
echo.
pause
endlocal
