@echo off
REM Headless FBX -> GLB conversion for UK1 Outboxer (TIGHT)
REM Aims for ~30-100MB: strips no-info textures, uses JPG, Draco compresses meshes.
REM Output: D:\AI project\browser_mocap\uk1_outboxer.glb

set BLENDER="C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"
set OUT_DIR=D:\AI project\browser_mocap
set LOGFILE=%OUT_DIR%\_convert_uk1.log
set PYSCRIPT=%OUT_DIR%\_convert_uk1.py

echo === UK1 FBX -^> GLB conversion (compact) === > "%LOGFILE%"
echo Start: %DATE% %TIME% >> "%LOGFILE%"

if not exist %BLENDER% (
    echo ERROR: Blender 5.1 not found at %BLENDER% >> "%LOGFILE%"
    echo ERROR: Blender 5.1 not found at %BLENDER%
    pause
    exit /b 1
)

REM Delete old bad export
if exist "%OUT_DIR%\uk1_outboxer.glb" del /q "%OUT_DIR%\uk1_outboxer.glb"

REM Run Blender headless with our python script (script is written next to the bat)
%BLENDER% --background --python "%PYSCRIPT%" >> "%LOGFILE%" 2>&1

echo End: %DATE% %TIME% >> "%LOGFILE%"

if exist "%OUT_DIR%\uk1_outboxer.glb" (
    echo SUCCESS: GLB created >> "%LOGFILE%"
    echo SUCCESS
) else (
    echo FAILED: no GLB produced. Check log. >> "%LOGFILE%"
    echo FAILED
)

timeout /t 2 >nul
