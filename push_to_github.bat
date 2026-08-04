@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================================
echo    CommArt  -  Push this project to YOUR GitHub repo
echo ============================================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Git is not installed, or not in PATH.
  echo         Download and install: https://git-scm.com/download/win
  echo         Then run this file again.
  echo.
  pause
  exit /b 1
)

echo BEFORE YOU CONTINUE:
echo   1. Go to  https://github.com/new
echo   2. Repository name:  commart
echo   3. Do NOT tick "Add a README file" / "Add .gitignore" / "license"
echo   4. Click "Create repository"
echo   5. Copy the URL shown at the top, it looks like:
echo         https://github.com/YOURNAME/commart.git
echo.

set "REPOURL="
set /p REPOURL=Paste the repo URL here, then press Enter: 

if "%REPOURL%"=="" (
  echo.
  echo [ABORT] No URL entered.
  pause
  exit /b 1
)

echo.
echo [1/4] Configuring remote ...
git remote remove origin >nul 2>&1
git remote add origin "%REPOURL%"
if errorlevel 1 goto fail

echo [2/4] Renaming local branch to "main" ...
git branch -M main

echo [3/4] Pushing to GitHub ...
echo       A sign-in window may pop up.
echo       Choose "Sign in with your browser" - you are already logged in,
echo       so it should complete in one click.
echo.
git push -u origin main
if errorlevel 1 goto fail

echo.
echo ============================================================
echo    [4/4] SUCCESS - code is now on GitHub.
echo ============================================================
echo.
echo NEXT STEPS to get the APK:
echo   1. Open your repo page on GitHub
echo   2. Click the "Actions" tab (top menu)
echo   3. Left side: click  "Build Android (APK)"
echo   4. Right side: click  "Run workflow"  -^>  green "Run workflow" button
echo   5. Wait ~3-6 minutes until the green check mark appears
echo   6. Click into that run, scroll down to "Artifacts"
echo   7. Download  "commart-android"  -  unzip it  -  that is your APK
echo.
pause
exit /b 0

:fail
echo.
echo ============================================================
echo    [FAILED] Something went wrong.
echo ============================================================
echo    Copy the error message shown above and send it to me,
echo    I will tell you exactly how to fix it.
echo.
pause
exit /b 1
