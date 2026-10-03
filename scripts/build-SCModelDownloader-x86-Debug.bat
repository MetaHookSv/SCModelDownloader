@echo off
setlocal
set "Configuration=Debug"
call "%~dp0build-SCModelDownloader-x86.bat" %*
exit /b %errorlevel%
