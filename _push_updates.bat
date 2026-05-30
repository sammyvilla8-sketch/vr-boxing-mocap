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
git commit -m "Fix UK1 not loading on Pages: serve GLB from the repo, not the release (CORS)" -m "GitHub Release asset URLs don't send Access-Control-Allow-Origin, so fetch() from the Pages-hosted page was blocked. The release exists and downloads in a normal browser tab but JS can't read it." -m "Fix: commit uk1_outboxer.glb (~67 MB) directly to the repo. GitHub Pages serves it from the same origin as index.html / ipad.html, eliminating the CORS issue. The 100 MB GitHub file-size limit is fine — 67 MB is well under." -m "loadUK1FromReleaseOrCache() now: 1) checks IndexedDB cache; 2) on file:// hands the local path to GLTFLoader directly; 3) otherwise streams ./uk1_outboxer.glb with the progress UI and caches it. Release URL no longer used." -m "Also commits the layout redesign from the previous round: corner-overlay camera by default (resizable), 'Split' (V) toggles side-by-side panels, 'Big 3D' (B) shrinks corner thumb, 'Popout Cam' (C) and 'Popout 3D' (P) open separate browser windows for second-monitor use."
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
