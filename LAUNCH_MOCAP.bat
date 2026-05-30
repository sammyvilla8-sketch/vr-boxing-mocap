@echo off
REM One-click launcher for VR Boxing Browser Mocap Tool
REM Opens the tool in a new Chrome window with UK1 already pre-loaded.

set CHROME="C:\Program Files\Google\Chrome\Application\chrome.exe"
set CHROME_X86="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
set TOOL_URL=file:///D:/AI%%20project/browser_mocap/index.html

set RNDQS=?v=%RANDOM%%RANDOM%

if exist %CHROME% (
    start "" %CHROME% --new-window --allow-file-access-from-files --disable-application-cache "%TOOL_URL%%RNDQS%"
) else if exist %CHROME_X86% (
    start "" %CHROME_X86% --new-window --allow-file-access-from-files --disable-application-cache "%TOOL_URL%%RNDQS%"
) else (
    echo Chrome not found in default install locations.
    echo Please launch index.html manually from: D:\AI project\browser_mocap\
    pause
)
