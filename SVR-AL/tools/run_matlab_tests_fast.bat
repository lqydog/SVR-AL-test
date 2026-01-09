@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT=%%~fI"

matlab -batch "cd('%ROOT%'); addpath(genpath('src')); addpath('tools'); run_ci('fast');"
set "EC=%ERRORLEVEL%"
exit /b %EC%

