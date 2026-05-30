@echo off
REM ============================================================
REM Push: 2D fallback Y-flip + hip-center, leg-bone skip on
REM low visibility, lock stick figure to rest bbox, default
REM stick figure to overlap mode.
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo === VR Boxing Mocap: tracking quality fixes ===
echo Folder: %CD%
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] git not on PATH.
  pause
  exit /b 1
)

if not exist .git (
  echo [ERROR] No .git folder.
  pause
  exit /b 1
)

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
echo.
echo [step 1b] git status:
git status --short
echo.

echo [step 2] git commit
git commit -m "Mocap quality: fix 2D fallback Y/hip, skip invisible legs, lock stick scale" -m "Diag from user showed pinned MediaPipe still doesn't emit poseWorldLandmarks (so we're always on the 2D fallback path), and the fallback had three issues that combined into 'noodle arms + legs through floor + stick figure jumping in size'." -m "Fix 1: 2D fallback flips Y (image-down -> world-up) and centers on hip midpoint (landmarks 23,24) instead of image midpoint. Matches what Kalidokit's runtime:'mediapipe' expects." -m "Fix 2: In driveCharacterFromPose, if max visibility across the MediaPipe landmarks driving a lower-body bone (knee/ankle/foot) is < 0.5, hold that bone in its rest pose. Desk-webcam framing usually only catches upper body — driving leg bones with garbage was contorting UK1's skinned mesh through the floor." -m "Fix 3: Cache UK1's bbox at model-load (T-pose) into APP.charRestBox. syncStickFigureToCharacter uses that stable reference instead of re-measuring the deformed skinned mesh every 60 frames — the stick figure no longer grows unboundedly when tracking glitches." -m "Fix 4: Default STICK.mode = 2 (overlap on top of UK1) instead of 1 (side-by-side off to the left). User explicitly asked for it on the character."
if errorlevel 1 (
  echo [info] Nothing to commit, or commit failed.
)

echo.
echo [step 3] git push origin main
git push origin main
if errorlevel 1 (
  echo.
  echo [ERROR] push failed.
  pause
  exit /b 1
)

echo.
echo ===============================================================
echo  PUSHED. Pages rebuilds in 1-3 min.
echo  After hard-reload, expect:
echo   - Stick figure on top of UK1 (overlap default)
echo   - Legs stay in rest pose if camera can't see them
echo   - UK1 size in [stickfig] log stays close to (1.62,1.75,0.34)
echo ===============================================================
echo.
pause
endlocal
