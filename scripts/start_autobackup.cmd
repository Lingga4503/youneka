@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\project\flow\scripts\autobackup.ps1" -Branch autobackup -IntervalSeconds 300
