@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Publish SSHD5014 course site to GitHub Pages (Windows).
REM Repo: https://github.com/Lazaruschan/2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-
REM
REM Usage (double-click or from CMD/PowerShell):
REM   cd Github\SSHD5014
REM   publish.bat
REM
REM You will be prompted for GitHub username + Personal Access Token (PAT).
REM Create a token: GitHub -^> Settings -^> Developer settings -^> Personal access tokens
REM After push: Settings -^> Pages -^> Deploy from branch -^> main / (root)

cd /d "%~dp0"

set "REPO_SLUG=Lazaruschan/2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-"
set "REPO_URL=https://github.com/%REPO_SLUG%.git"
set "BRANCH=main"
set "REMOTE=origin"
set "PAGES_URL=https://lazaruschan.github.io/2026-1-SSHD5014-USER-CENTRED-DESIGN-IN-DIGITAL-MEDIA-Group-A01-/"

echo ==^> Publishing from: %CD%
echo ==^> Target: %REPO_URL%
echo.

REM --- Credentials (prompted; not saved to disk) ---
echo Enter GitHub credentials for upload
echo Use a Personal Access Token as the password ^(not your GitHub account password^).
echo.
set "GH_USER="
set /p "GH_USER=GitHub username: "
if not defined GH_USER (
  echo Error: username is required.
  pause
  exit /b 1
)

REM Masked token input via PowerShell when available
set "GH_TOKEN="
where powershell >nul 2>&1
if not errorlevel 1 (
  for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "$t = Read-Host 'Personal Access Token (PAT)' -AsSecureString; $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($t); [Runtime.InteropServices.Marshal]::PtrToStringAuto($b)"`) do set "GH_TOKEN=%%T"
) else (
  set /p "GH_TOKEN=Personal Access Token (PAT): "
)

if not defined GH_TOKEN (
  echo Error: token is required.
  pause
  exit /b 1
)

REM URL-encode username/token for HTTPS push (handles special characters)
for /f "usebackq delims=" %%U in (`powershell -NoProfile -Command "[uri]::EscapeDataString($env:GH_USER)"`) do set "GH_USER_ENC=%%U"
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "[uri]::EscapeDataString($env:GH_TOKEN)"`) do set "GH_TOKEN_ENC=%%P"
if not defined GH_USER_ENC set "GH_USER_ENC=%GH_USER%"
if not defined GH_TOKEN_ENC set "GH_TOKEN_ENC=%GH_TOKEN%"

set "PUSH_URL=https://!GH_USER_ENC!:!GH_TOKEN_ENC!@github.com/%REPO_SLUG%.git"
echo.
echo ==^> Credentials captured for this session only ^(not written to .git/config^)
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo Error: git is not installed or not on PATH.
  echo Install Git for Windows: https://git-scm.com/download/win
  pause
  exit /b 1
)

if not exist ".git\" (
  echo ==^> git init
  git init
  if errorlevel 1 goto :fail
)

REM Keep ignore list current
(
  echo node_modules/
  echo .DS_Store
  echo *.log
  echo *.rtf
  echo start.rtf
  echo .env
  echo .env.*
  echo *token*
  echo *secret*
) > .gitignore

REM Remove secret-prone files from disk if present
if exist "start.rtf" del /f /q "start.rtf" >nul 2>&1
del /f /q "*.rtf" >nul 2>&1

REM Refresh tutorial worksheet PDFs from Notes
if exist "%~dp0sync-tutorial-notes.bat" (
  echo ==^> Syncing tutorial notes PDFs
  call "%~dp0sync-tutorial-notes.bat"
  if errorlevel 1 echo Warning: tutorial notes sync skipped ^(source missing?^)
)

echo ==^> Staging site files only ^(explicit allow-list^)
git add --force ^
  .gitignore ^
  .nojekyll ^
  README.md ^
  index.html ^
  auth.js ^
  assets ^
  slides ^
  tutorial-notes ^
  readings ^
  publish.sh ^
  publish.bat ^
  export-slides.sh ^
  sync-tutorial-notes.sh ^
  sync-tutorial-notes.bat ^
  embed-slide-assets.py ^
  package.json ^
  package-lock.json
if errorlevel 1 goto :fail

REM Never publish secrets / tooling junk
git rm -r --cached node_modules >nul 2>&1
git rm --cached start.rtf >nul 2>&1
git rm --cached -f *.rtf >nul 2>&1

echo ==^> Staged files:
git status --short

git diff --cached --quiet
if errorlevel 1 (
  echo ==^> Committing
  git commit -m "Publish SSHD5014 User-centred Design in Digital Media course website."
  if errorlevel 1 goto :fail
) else (
  git rev-parse HEAD >nul 2>&1
  if errorlevel 1 (
    echo Error: nothing to commit and no previous commits.
    goto :fail
  )
  echo ==^> No new changes; will push existing commits.
)

git branch -M "%BRANCH%"
if errorlevel 1 goto :fail

REM Keep remote URL clean (no username/token stored)
git remote get-url "%REMOTE%" >nul 2>&1
if errorlevel 1 (
  echo ==^> Adding remote %REMOTE%
  git remote add "%REMOTE%" "%REPO_URL%"
) else (
  echo ==^> Updating remote %REMOTE%
  git remote set-url "%REMOTE%" "%REPO_URL%"
)
if errorlevel 1 goto :fail

echo ==^> Pushing to %REMOTE%/%BRANCH% as %GH_USER%
git -c credential.helper= push -u "!PUSH_URL!" "%BRANCH%"
if errorlevel 1 goto :fail

REM Clear secrets from this session
set "GH_TOKEN="
set "GH_TOKEN_ENC="
set "PUSH_URL="

echo.
echo Done.
echo Enable Pages ^(once^): repo Settings -^> Pages -^> Deploy from branch -^> main / ^(root^)
echo Site URL: %PAGES_URL%
echo Site password: 20265014
echo.
pause
exit /b 0

:fail
set "GH_TOKEN="
set "GH_TOKEN_ENC="
set "PUSH_URL="
echo.
echo Publish failed. Check username/token ^(repo scope needed^) and messages above.
pause
exit /b 1
