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
set "PYTHON_URL=https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe"
set "VBS_PATH=%TEMP%\create_shortcut.vbs"

:: Check if Python is installed correctly
python --version 2>&1 | findstr /I "not found" >nul
if %errorlevel% equ 0 (
    echo Python doesn't installed
    echo please wait downloading python
    powershell -Command "& {Invoke-WebRequest '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'}"
    echo Installing Python 13.2
    start /wait "" "%PYTHON_INSTALLER%" /quiet PrependPath=1 InstallAllUsers=1
    del "%PYTHON_INSTALLER%"
) else (
    echo Python is already installed.
)

python -m pip install keyboard

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo Creating python script 

echo import keyboard > %SCRIPT_PATH%
echo import ctypes >> %SCRIPT_PATH%
echo import time >> %SCRIPT_PATH%
echo. >> %SCRIPT_PATH%
echo VK_VOLUME_MUTE = 0xAD >> %SCRIPT_PATH%
echo VK_VOLUME_DOWN = 0xAE >> %SCRIPT_PATH%
echo VK_VOLUME_UP = 0xAF >> %SCRIPT_PATH%
echo. >> %SCRIPT_PATH%
echo def press_key(vk_code, times=2, delay_after=0): >> %SCRIPT_PATH%
echo     for _ in range(times): >> %SCRIPT_PATH%
echo         ctypes.windll.user32.keybd_event(vk_code, 0, 0, 0) >> %SCRIPT_PATH%
echo         ctypes.windll.user32.keybd_event(vk_code, 0, 2, 0) >> %SCRIPT_PATH%
echo         time.sleep(0.05) >> %SCRIPT_PATH%
echo. >> %SCRIPT_PATH%
echo     if delay_after ^> 0: >> %SCRIPT_PATH%
echo         time.sleep(delay_after) >> %SCRIPT_PATH%
echo. >> %SCRIPT_PATH%
echo keyboard.add_hotkey("win+page up", lambda: press_key(VK_VOLUME_UP, 2)) >> %SCRIPT_PATH%
echo keyboard.add_hotkey("win+page down", lambda: press_key(VK_VOLUME_DOWN, 2)) >> %SCRIPT_PATH%
echo keyboard.add_hotkey("win+end", lambda: press_key(VK_VOLUME_MUTE, 1, 0.5)) >> %SCRIPT_PATH%
echo keyboard.wait() >> %SCRIPT_PATH%

:: Create startup shortcut
powershell -command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = 'pythonw.exe'; $s.Arguments = '\"%INSTALL_DIR%\%SCRIPT_NAME%\"'; $s.Save()"

start "" pythonw "%SCRIPT_PATH%"

echo Setup completed!
echo Now you can use volumehotkey
pause