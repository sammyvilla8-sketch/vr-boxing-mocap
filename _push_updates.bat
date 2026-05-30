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
git commit -m "Robust character framing: bone-based bounds + clamped zoom + Frame (F) key" -m "Sammy report: UK1 loaded but at huge scale — only the foot was visible, zooming out lost the character. Cause: Box3.setFromObject on a SkinnedMesh before world matrices have been updated returns a wildly wrong size (often near-zero), so the 'auto-scale to 1.8m' math divides 1.8 / 0.05 = 36x and the character ends up ~36 m tall. Camera at (2.0, 1.6, 3.0) is then inside the character's foot." -m "Fix: getCharacterBounds() walks all bones (whose world positions ARE accurate after one updateMatrixWorld call) plus any non-skinned meshes, returning a sane bounding box. onModelLoaded calls it twice (before and after auto-scale) and now requires sz.y > 0.02 before scaling, so a near-zero measurement can't multiply the model to infinity." -m "frameCharacter() then sets OrbitControls.target to the character center, places the camera at FOV-derived distance, and clamps controls.minDistance (height*0.25) and maxDistance (height*12) so rotate + zoom stay focused on the character. Also adjusts camera.near/far for the right depth range." -m "F key + on-screen 'Frame' button (top-right of 3D panel on both desktop and iPad) re-runs frameCharacter() anytime, so if you ever lose the character you tap F to recover." -m "Also commits the previous round (CORS fix: GLB committed to repo, same-origin fetch) so both arrive together."
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
