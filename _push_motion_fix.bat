@echo off
REM ============================================================
REM Push the MediaPipe Holistic version pin + 2D fallback.
REM Root cause: unpinned @mediapipe/holistic latest stopped emitting
REM poseWorldLandmarks, killing the whole motion pipeline.
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo === VR Boxing Mocap: pin MediaPipe + 2D fallback ===
echo Folder: %CD%
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] git not on PATH. Install Git for Windows then re-run.
  pause
  exit /b 1
)

if not exist .git (
  echo [ERROR] No .git folder.
  pause
  exit /b 1
)

REM Clean any stale .git/index.lock left behind by a crashed git
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
git commit -m "Pin MediaPipe Holistic to 0.5.1675471629 + add 2D fallback" -m "Bug: the unpinned @mediapipe/holistic/holistic.js on jsDelivr started returning poseLandmarks (2D, drives the webcam dots) without poseWorldLandmarks (3D world meters). Our onHolisticResults requires both, so it early-returned on every frame and never called driveCharacterFromPose or updateStickFigure. From the user's side this looked like 'tracking dots visible but nothing moves' — lostFrames climbing to 2948 with diagFrameCount undefined." -m "Fix part 1: pin the Holistic script tag and locateFile to the known-good version 0.5.1675471629 in both index.html and ipad.html." -m "Fix part 2: if poseWorldLandmarks is still missing for any reason, synthesize a pseudo-world array from poseLandmarks (center on 0.5, scale to ~1.75m body height). This means motion never fully dies on a future MediaPipe behavior change."
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
  echo Then re-run this script.
  pause
  exit /b 1
)

echo.
echo ===============================================================
echo  PUSHED.
echo  Desktop: https://sammyvilla8-sketch.github.io/vr-boxing-mocap/
echo  iPad:    https://sammyvilla8-sketch.github.io/vr-boxing-mocap/ipad.html
echo  Pages auto-rebuilds in 1-3 min. Hard-reload after.
echo ===============================================================
echo.
pause
endlocal
