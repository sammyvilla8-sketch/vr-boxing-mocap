@echo off
REM ============================================================
REM Push: remove double Y-flip (stick figure was upside-down),
REM hide UK1 SkeletonHelper by default (S key still toggles).
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo === VR Boxing Mocap: fix upside-down stick + hide debug rig ===
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
git commit -m "Fix upside-down stick figure + hide CC5 rig debug helper" -m "Bug 1: 2D fallback was negating Y to convert image-down -> world-up, but updateStickFigure's lmToLocal also negates Y (it was written assuming MediaPipe's image-down convention). Double-negation made the stick figure upside-down. Removed the flip in the fallback so it matches MediaPipe's poseWorldLandmarks convention." -m "Bug 2: showSkeleton defaulted to true, which made THREE.SkeletonHelper render all 101 CC5 bones (including toe/jaw/finger/breast bones) as colored lines. With dangling foot/toe bones near y=0 it looked like 'a skeleton on the floor' next to the character. Default to false; S key still toggles for debugging." -m "Combined effect: page now shows just UK1 + the cyan MediaPipe stick figure (overlap mode, right-side-up) once webcam starts."
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
