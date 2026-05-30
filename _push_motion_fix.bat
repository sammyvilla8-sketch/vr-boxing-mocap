@echo off
REM ============================================================
REM Push: clamp stick figure to body, hide low-vis stick lines,
REM tighten euro filter (less wild bone swings), fix popout
REM black-screen by overriding #center grid placement.
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo === VR Boxing Mocap: scale clamp + smooth + popout fix ===
echo Folder: %CD%
echo.

where git >nul 2>&1
if errorlevel 1 ( echo [ERROR] git not on PATH. & pause & exit /b 1 )
if not exist .git ( echo [ERROR] No .git folder. & pause & exit /b 1 )

if exist ".git\index.lock" (
  echo [step 0] removing stale .git\index.lock
  del /f /q ".git\index.lock"
)

git config user.email "sammyvilla8@gmail.com"
git config user.name "sammyvilla8-sketch"

echo [step 1] git add -A
git add -A
git status --short
echo.

echo [step 2] git commit
git commit -m "Stick figure scale clamp, tighter smoothing, popout fix" -m "Symptom 1 (skeleton bigger than character): MediaPipe hallucinates lower-body landmarks at extreme positions when only upper body is in frame. Multiplied by H=1.75 they extended the stick figure far past UK1. Fix: clamp each axis to +/-1.2m in updateStickFigure's lmToLocal, and skip drawing line segments whose endpoints have visibility < 0.5." -m "Symptom 2 (moves like crazy after calibration): one-euro filter defaults (minCutoff=1.2, beta=0.08) weren't smoothing enough for the noisier 2D-derived pose. Tightened to (minCutoff=0.6, beta=0.02) — bone rotations now interpolate smoothly even when raw pose jitters." -m "Symptom 3 (popout black screen): #center had hardcoded grid-column:2/3 from the 3-column desktop layout. Popout modes collapse the grid to 1 column, so column 2 didn't exist and #center sized to zero, the canvas to zero, and the WebGL resize() bailed on !w||!h. Fix: override #center grid-column/grid-row to 1/-1 with !important in popout-mode and popout-cam-mode CSS."
if errorlevel 1 ( echo [info] Nothing to commit. )

echo.
echo [step 3] git push origin main
git push origin main
if errorlevel 1 ( echo [ERROR] push failed. & pause & exit /b 1 )

echo.
echo ===============================================================
echo  PUSHED. Pages rebuilds in 1-3 min. Empty Cache + Hard Reload.
echo ===============================================================
echo.
pause
endlocal
