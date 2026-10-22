@echo off
cd /d "%~dp0"
set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
    echo Godot executable tidak ditemukan di: "%GODOT_EXE%"
    pause
    exit /b 1
)
start "" "%GODOT_EXE%" --path .
