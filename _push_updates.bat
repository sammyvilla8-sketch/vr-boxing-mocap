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
git commit -m "Fix UK1 scale via skeleton measurement + auto-redirect mobile to ipad.html" -m "UK1 was rendering ~5-10x oversized because Box3.setFromObject on a SkinnedMesh reads bind-pose vertices in mesh-local space, NOT the actually-rendered geometry (which is bind-pose vertices transformed by bones at skin time). The CC5 rig has Armature scale + inverse-bind matrices that make mesh bounds report ~1.77m while the rendered character is much bigger." -m "Replace with skeleton-based measurement: find CC_Base_Head and CC_Base_L_Foot bones, take Y delta of their world positions, add a small skull-cap offset. Falls back to mesh bounds if bones cannot be located. Logs the chosen bone names and resulting height for QA." -m "Also added an early-running redirect script in index.html that sends touch devices / narrow viewports to ipad.html. Escape hatch: ?desktop=1 forces the desktop view."
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
