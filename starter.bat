@echo off
title Запуск скрипта от имени администратора
color 0A

echo ========================================
echo   Запуск скрипта с правами администратора
echo ========================================
echo.

powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"Get-Content -Path ''C:\Users\karic\Desktop\script\atest.ps1'' -Encoding UTF8 ^| Set-Content -Path ''%TEMP%\temp.ps1'' -Encoding UTF8; ^& ''%TEMP%\temp.ps1''; pause\"'"
