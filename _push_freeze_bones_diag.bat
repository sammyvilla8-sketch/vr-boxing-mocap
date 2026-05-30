@echo off
cd /d "D:\AI project\browser_mocap"
echo === Removing stale git lock ===
if exist .git\index.lock del /f /q .git\index.lock
echo === Resetting staging area ===
git reset
echo === Staging only what changed ===
git add index.html _push_freeze_bones_diag.bat
echo === Committing ===
git commit -m "T-pose 3s countdown + popout keeps debug panel + popout sliders drive opener APP"
echo === Pushing ===
git push origin main
echo.
echo === DONE — close window and reload page with ?fresh=1 ===
pause
