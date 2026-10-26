@echo off
cd /d "%~dp0"
if not exist server\node_modules call npm run install:all
if not exist client\node_modules call npm run install:all
if not exist server\.env copy server\.env.example server\.env
echo Starting Apex on http://localhost:5173 ...
call npm run dev
