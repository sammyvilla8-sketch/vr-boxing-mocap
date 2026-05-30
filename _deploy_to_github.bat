@echo off
REM ============================================================
REM   VR Boxing Mocap - One-click GitHub Pages deploy
REM
REM   What this does:
REM   1. Cleans any partial .git folder from a previous attempt
REM   2. Initializes a fresh git repo (excludes 478 MB uk1_outboxer.glb)
REM   3. Commits everything
REM   4. Creates a public GitHub repo + pushes (via gh CLI if available),
REM      or sets the remote and pushes if you've already created the repo.
REM   5. Enables GitHub Pages
REM
REM   Run this from a Command Prompt in D:\AI project\browser_mocap
REM ============================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo === VR Boxing Mocap - deploy ===
echo Folder: %CD%
echo.

REM ----- Step 0: ensure git is on PATH -----
where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] git is not on PATH. Install Git for Windows from https://git-scm.com/download/win and re-run.
  pause
  exit /b 1
)

REM ----- Step 1: clean any stale .git from a sandbox-created init -----
if exist .git (
  echo [step 1] Removing existing .git folder...
  rmdir /s /q .git
  if exist .git (
    echo [WARN] Could not fully remove .git. Try deleting it manually in Explorer ^(show hidden files^) and re-run.
    pause
    exit /b 1
  )
)

REM ----- Step 2: fresh init + commit -----
echo [step 2] git init...
git init -b main
git config user.email "sammyvilla8@gmail.com"
git config user.name "sammyvilla8-sketch"

echo [step 2] git add (uk1_outboxer.glb is excluded via .gitignore)
git add -A
git status --short

echo [step 2] commit...
git commit -m "Initial commit: desktop + iPad mocap tool"
if errorlevel 1 (
  echo [ERROR] commit failed.
  pause
  exit /b 1
)

REM ----- Step 3: create repo + push -----
where gh >nul 2>&1
if errorlevel 1 (
  echo.
  echo [step 3] GitHub CLI ^(gh^) not found. Falling back to manual remote setup.
  echo.
  echo   You need to create the repo yourself first:
  echo     1. Go to https://github.com/new
  echo     2. Owner: sammyvilla8-sketch
  echo     3. Repository name: vr-boxing-mocap
  echo     4. Public ^(required for free GitHub Pages^)
  echo     5. DO NOT initialize with README/gitignore/license
  echo     6. Click "Create repository"
  echo.
  echo Press any key once the empty repo exists on GitHub...
  pause

  git remote add origin https://github.com/sammyvilla8-sketch/vr-boxing-mocap.git
  echo.
  echo [step 3] pushing to main...
  git push -u origin main
  if errorlevel 1 (
    echo.
    echo [ERROR] git push failed. If it complains about authentication, run:
    echo   git config --global credential.helper manager
    echo and re-run this script. Or push manually:
    echo   git push -u origin main
    pause
    exit /b 1
  )
  echo.
  echo [step 4] Now enable Pages manually:
  echo   1. https://github.com/sammyvilla8-sketch/vr-boxing-mocap/settings/pages
  echo   2. Source: "Deploy from a branch"
  echo   3. Branch: main / ^(root^)
  echo   4. Save.
  echo.
  goto :urls
)

REM gh CLI is available
echo [step 3] gh CLI detected. Checking auth...
gh auth status >nul 2>&1
if errorlevel 1 (
  echo [step 3] not authenticated. Running: gh auth login
  echo Pick "GitHub.com" then "HTTPS" then follow the browser prompt.
  gh auth login
  if errorlevel 1 (
    echo [ERROR] gh auth failed. Re-run script after you're signed in.
    pause
    exit /b 1
  )
)

echo [step 3] Creating public repo sammyvilla8-sketch/vr-boxing-mocap and pushing...
gh repo create sammyvilla8-sketch/vr-boxing-mocap --public --source=. --remote=origin --push --description "Browser-based VR boxing mocap (desktop + iPad). MediaPipe + KalidoKit + CC5 retarget."
if errorlevel 1 (
  echo [WARN] gh repo create failed ^(repo may already exist^). Trying to add remote and push directly...
  git remote add origin https://github.com/sammyvilla8-sketch/vr-boxing-mocap.git 2>nul
  git push -u origin main
  if errorlevel 1 (
    echo [ERROR] push failed.
    pause
    exit /b 1
  )
)

echo.
echo [step 4] Enabling GitHub Pages...
gh api -X POST "repos/sammyvilla8-sketch/vr-boxing-mocap/pages" -f "source[branch]=main" -f "source[path]=/" 2>nul
if errorlevel 1 (
  echo [info] Pages API call returned non-zero. It may already be enabled. Verify at:
  echo   https://github.com/sammyvilla8-sketch/vr-boxing-mocap/settings/pages
)

:urls
echo.
echo ===============================================================
echo  DEPLOYED. Pages can take 1-5 minutes to provision on first push.
echo.
echo  Desktop: https://sammyvilla8-sketch.github.io/vr-boxing-mocap/
echo  iPad:    https://sammyvilla8-sketch.github.io/vr-boxing-mocap/ipad.html
echo.
echo  NOTE: uk1_outboxer.glb (478 MB) is NOT hosted (over GitHub's
echo  100 MB file limit). On the iPad version, tap "Load Character"
echo  and pick a GLB from Files / iCloud / Drive once.
echo.
echo  To host UK1 as a release asset (one-time, optional):
echo    gh release create v1 uk1_outboxer.glb --title "UK1 Character"
echo    Then the "Load UK1" button can fetch from:
echo    https://github.com/sammyvilla8-sketch/vr-boxing-mocap/releases/download/v1/uk1_outboxer.glb
echo ===============================================================
echo.
pause
