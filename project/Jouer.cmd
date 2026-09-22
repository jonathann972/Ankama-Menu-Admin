@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0serveur-local\Demarrer.ps1"
if errorlevel 1 (
    pause
    exit /b 1
)
cd /d "%~dp0serveur-local\launcher"
start "" "Giny.Uplauncher.exe"
