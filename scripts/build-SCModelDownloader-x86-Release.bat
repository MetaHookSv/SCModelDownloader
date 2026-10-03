@echo off
setlocal
set "Configuration=Release"
call "%~dp0build-SCModelDownloader-x86.bat" %*
exit /b %errorlevel%
