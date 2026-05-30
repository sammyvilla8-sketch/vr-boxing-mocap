@echo off
REM ============================================================
REM Push the motion-pipeline diagnostic fix + restored bottom-of-file content.
REM Run this from the browser_mocap folder (or just double-click).
REM Idempotent: re-run if push fails partway.
REM ============================================================

setlocal
cd /d "%~dp0"

echo.
echo === VR Boxing Mocap: push motion-pipeline fix ===
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
echo.
echo [step 1b] git status:
git status --short
echo.

echo [step 2] git commit
git commit -m "Mocap pipeline: run stick figure before KalidoKit + add diag log" -m "Bug: in the previous code, if Kalidokit.Pose.solve() threw or returned null, onHolisticResults early-returned BEFORE updateStickFigure ran. That meant any upstream Kalidokit failure silently killed both the UK1 driver AND the cyan stick figure — looking like a total motion regression." -m "Fix: (a) call updateStickFigure first (raw MediaPipe landmarks; no Kalidokit dep), so the cyan stick figure keeps moving even if Kalidokit fails. (b) Wrap driveCharacterFromPose in try/catch so a bone-driver crash doesn't kill subsequent frames. (c) Add a throttled [mocap-diag] console.log (~once per 2s) showing haveBody / kalido / LeftUpperArm.quat / stickVisibleJoints / calibrated — paste this when motion goes missing so we can pinpoint which stage stalled." -m "Mirrored in ipad.html. Also restored truncated bottom-of-file content (BOOT block) that had been lost from local working copies."
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
echo  After it rebuilds, reload the page and open DevTools console.
echo  When MediaPipe sees you, you should see [mocap-diag] log lines
echo  ~every 2 seconds showing haveBody / kalido / bone quaternions.
echo ===============================================================
echo.
pause
endlocal
