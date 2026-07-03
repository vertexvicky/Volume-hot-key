@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~fnx0\"' -Verb RunAs"
    exit /b
)

setlocal EnableDelayedExpansion

set "INSTALL_DIR=%ProgramData%\volumehotkey"
set "SCRIPT_NAME=volumehotkey.py"
set "SCRIPT_PATH=%INSTALL_DIR%\%SCRIPT_NAME%"
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT_NAME=VolumeHotkey.lnk"
set "SHORTCUT_PATH=%STARTUP_FOLDER%\%SHORTCUT_NAME%"
set "PYTHON_INSTALLER=%TEMP%\python_installer.exe"

:: 1. DYNAMIC FUNCTION TO LOCATE PYTHON ON THE SYSTEM
:search_python
set "REAL_PYTHON_EXE="

:: Method A: Scan system PATH (ignoring WindowsApps)
for /f "delims=" %%I in ('where python 2^>nul') do (
    echo %%I | findstr /I "WindowsApps" >nul
    if errorlevel 1 (
        set "REAL_PYTHON_EXE=%%I"
        goto :found_python
    )
)

:: Method B: Scan standard Program Files installation paths directly
for /d %%D in ("C:\Program Files\Python3*") do (
    if exist "%%D\python.exe" (
        set "REAL_PYTHON_EXE=%%D\python.exe"
    )
)

:: Method C: Scan local user AppData paths directly
if "!REAL_PYTHON_EXE!"=="" (
    for /d %%D in ("%LOCALAPPDATA%\Programs\Python\Python3*") do (
        if exist "%%D\python.exe" (
            set "REAL_PYTHON_EXE=%%D\python.exe"
        )
    )
)
:found_python

:: 2. IF STILL NOT FOUND, DOWNLOAD AND INSTALL IT
if "!REAL_PYTHON_EXE!"=="" (
    echo No valid Python installation detected.
    echo Resolving the latest stable Python release URL...
    
    for /f "delims=" %%u in ('powershell -Command "$html = Invoke-WebRequest 'https://www.python.org/downloads/windows/' -UseBasicParsing; $url = $html.Links | Where-Object { $_.href -match 'python-3\.\d+\.\d+-amd64\.exe' } | Select-Object -First 1 -ExpandProperty href; echo $url"') do set "PYTHON_URL=%%u"
    
    echo Downloading from: !PYTHON_URL!
    powershell -Command "& {Invoke-WebRequest '!PYTHON_URL!' -OutFile '%PYTHON_INSTALLER%'}"
    
    echo Installing latest Python silently...
    start /wait "" "%PYTHON_INSTALLER%" /quiet PrependPath=1 InstallAllUsers=1
    del "%PYTHON_INSTALLER%"
    
    :: Run the search sequence one more time to catch the newly installed folder paths
    goto :search_python
)

:: FIX: Safely convert to pythonw.exe using proper delayed expansion syntax
set "REAL_PYTHON_EXE=!REAL_PYTHON_EXE!"
set "REAL_PYTHONW_EXE=!REAL_PYTHON_EXE:\python.exe=\pythonw.exe!"

echo Using Python Executable: !REAL_PYTHON_EXE!
echo Using Background Executable: !REAL_PYTHONW_EXE!

:: 3. Install dependency using the actual localized environment
echo Installing required 'keyboard' package...
"!REAL_PYTHON_EXE!" -m pip install keyboard

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Creating Python script...
echo import keyboard > "%SCRIPT_PATH%"
echo import ctypes >> "%SCRIPT_PATH%"
echo import time >> "%SCRIPT_PATH%"
echo. >> "%SCRIPT_PATH%"
echo VK_VOLUME_MUTE = 0xAD >> "%SCRIPT_PATH%"
echo VK_VOLUME_DOWN = 0xAE >> "%SCRIPT_PATH%"
echo VK_VOLUME_UP = 0xAF >> "%SCRIPT_PATH%"
echo. >> "%SCRIPT_PATH%"
echo def press_key(vk_code, times=2, delay_after=0): >> "%SCRIPT_PATH%"
echo      for _ in range(times): >> "%SCRIPT_PATH%"
echo          ctypes.windll.user32.keybd_event(vk_code, 0, 0, 0) >> "%SCRIPT_PATH%"
echo          ctypes.windll.user32.keybd_event(vk_code, 0, 2, 0) >> "%SCRIPT_PATH%"
echo          time.sleep(0.05) >> "%SCRIPT_PATH%"
echo. >> "%SCRIPT_PATH%"
echo      if delay_after ^> 0: >> "%SCRIPT_PATH%"
echo          time.sleep(delay_after) >> "%SCRIPT_PATH%"
echo. >> "%SCRIPT_PATH%"
echo keyboard.add_hotkey("win+page up", lambda: press_key(VK_VOLUME_UP, 2)) >> "%SCRIPT_PATH%"
echo keyboard.add_hotkey("win+page down", lambda: press_key(VK_VOLUME_DOWN, 2)) >> "%SCRIPT_PATH%"
echo keyboard.add_hotkey("win+end", lambda: press_key(VK_VOLUME_MUTE, 1, 0.5)) >> "%SCRIPT_PATH%"
echo keyboard.wait() >> "%SCRIPT_PATH%"

:: 4. Generate startup shortcut leveraging the dynamic path
echo Creating startup shortcut...
powershell -command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '!REAL_PYTHONW_EXE!'; $s.Arguments = '\"%SCRIPT_PATH%\"'; $s.Save()"

:: Launch immediately
start "" "!REAL_PYTHONW_EXE!" "%SCRIPT_PATH%"

echo Setup completed successfully!
pause
