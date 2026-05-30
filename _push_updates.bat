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
git commit -m "Split-panel UI (webcam + 3D side-by-side) + UK1 release auto-fetch with IndexedDB cache" -m "- Both index.html (desktop) and ipad.html now use a split layout: real-life webcam/video on the left (~30%%) with MediaPipe landmark dots, clean 3D scene on the right (~70%%) with character + cyan stick figure overlay." -m "- Desktop: B = toggle Big 3D (webcam shrinks to 200px corner thumb). P = open the 3D scene in a separate browser window so it can live on a second monitor. The popout shares the opener's three.js scene by reference." -m "- iPad: same split with landscape (side-by-side) / portrait (top/bottom) responsive variants. Big 3D toggle button on-screen. No popout (iOS Safari doesn't support multi-window)." -m "- UK1 GLB is fetched from the v1 GitHub Release on first load and cached in IndexedDB; subsequent loads are instant. Progress bar shows MB/MB during the one-time fetch. On file:// or localhost, prefers local ./uk1_outboxer.glb sidecar so the desktop launcher keeps working." -m "- Clear UK1 cache button in the Model panel (desktop) / Character card (iPad)." -m "- Helper: _upload_uk1_release.bat creates the v1 release with the GLB attached via gh CLI."
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
