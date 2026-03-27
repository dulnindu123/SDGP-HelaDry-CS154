@echo off
title HelaDry Python Backend Server
echo Starting HelaDry Backend Server...
echo -----------------------------------

:loop
echo [%time%] Starting server...
python -m Backend.app
echo [%time%] Server stopped or crashed. Restarting in 5 seconds...
timeout /t 5 /nobreak >nul
goto loop
