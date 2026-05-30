@echo off
REM Installs the one-click launcher on Sammy's Desktop.
REM Just double-click this once -- it copies LAUNCH_MOCAP.bat to your Desktop
REM with a friendly name. After that, you'll see "VR Boxing Mocap Tool.bat" on
REM your Desktop and double-clicking it opens the tool with UK1 pre-loaded.

set SRC=%~dp0LAUNCH_MOCAP.bat
set DST=%USERPROFILE%\Desktop\VR Boxing Mocap Tool.bat

echo Source: %SRC%
echo Dest:   %DST%
echo.

copy /Y "%SRC%" "%DST%"

if exist "%DST%" (
    echo.
    echo SUCCESS: "VR Boxing Mocap Tool.bat" is now on your Desktop.
    echo Double-click it any time to launch the mocap tool with UK1 loaded.
) else (
    echo.
    echo ERROR: copy failed. You can drag LAUNCH_MOCAP.bat to your Desktop manually.
)

timeout /t 5 >nul
