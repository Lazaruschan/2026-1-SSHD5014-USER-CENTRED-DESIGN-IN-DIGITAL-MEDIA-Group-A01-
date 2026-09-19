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
REM #region agent log
set "DEBUG_LOG=%~dp0..\..\debug-e10825.log"
set "DEBUG_HELPER=%~dp0_debug_log.ps1"
REM #endregion

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

REM OneDrive can break Git atomic appends to .git/logs/HEAD — disable for this repo
git config windows.appendAtomically false

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

REM #region agent log
set "HEAD_ATTR="
if exist ".git\logs\HEAD" for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Item '.git\logs\HEAD' -Force).Attributes"') do set "HEAD_ATTR=%%A"
for /f "delims=" %%A in ('git config --get windows.appendAtomically') do set "APPEND_VAL=%%A"
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "A" -Location "publish.bat:pre-commit" -Message "Pre-commit state" -DataJson "{\"inOneDrive\":true,\"appendAtomically\":\"!APPEND_VAL!\",\"headLogAttrs\":\"!HEAD_ATTR!\"}"
REM #endregion

git diff --cached --quiet
if errorlevel 1 (
  echo ==^> Committing
  git commit -m "Publish SSHD5014 User-centred Design in Digital Media course website." > "%TEMP%\sshd5014-commit-out.txt" 2>&1
  set "COMMIT_RC=!ERRORLEVEL!"
  type "%TEMP%\sshd5014-commit-out.txt"
  REM #region agent log
  powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "A" -Location "publish.bat:commit" -Message "Commit result" -DataJson "{\"exitCode\":!COMMIT_RC!,\"appendAtomically\":\"!APPEND_VAL!\"}" -OutputFile "%TEMP%\sshd5014-commit-out.txt"
  REM #endregion
  if not "!COMMIT_RC!"=="0" goto :fail
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

REM #region agent log
echo ==^> Fetching remote for divergence check
git -c credential.helper= fetch "!PUSH_URL!" "%BRANCH%" > "%TEMP%\sshd5014-fetch-out.txt" 2>&1
set "FETCH_RC=!ERRORLEVEL!"
type "%TEMP%\sshd5014-fetch-out.txt"
set "LOCAL_HEAD="
set "REMOTE_HEAD="
set "ROOT_COMMIT="
set "MERGE_BASE="
set "AHEAD=0"
set "BEHIND=0"
set "LOCAL_COUNT=0"
for /f %%H in ('git rev-parse HEAD 2^>nul') do set "LOCAL_HEAD=%%H"
for /f %%R in ('git rev-parse "origin/%BRANCH%" 2^>nul') do set "REMOTE_HEAD=%%R"
for /f %%P in ('git rev-list --max-parents^=0 HEAD 2^>nul') do set "ROOT_COMMIT=%%P"
for /f %%C in ('git rev-list --count HEAD 2^>nul') do set "LOCAL_COUNT=%%C"
for /f %%M in ('git merge-base HEAD "origin/%BRANCH%" 2^>nul') do set "MERGE_BASE=%%M"
for /f "tokens=1,2" %%A in ('git rev-list --left-right --count HEAD..."origin/%BRANCH%" 2^>nul') do (
  set "AHEAD=%%A"
  set "BEHIND=%%B"
)
set "HAS_ISO=0"
if exist "readings\ISO9241-210_2019.pdf" set "HAS_ISO=1"
set "HAS_SAMPLE=0"
if exist "readings\ISO9241-210_2019_sample.pdf" set "HAS_SAMPLE=1"
set "UNRELATED=false"
if "!MERGE_BASE!"=="" set "UNRELATED=true"
set "IS_ORPHAN=false"
if /I "!ROOT_COMMIT!"=="!LOCAL_HEAD!" set "IS_ORPHAN=true"
if "!LOCAL_COUNT!"=="1" if "!MERGE_BASE!"=="" set "IS_ORPHAN=true"
if "!LOCAL_COUNT!"=="2" if "!MERGE_BASE!"=="" set "IS_ORPHAN=true"
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "A" -Location "publish.bat:pre-push" -Message "History divergence check" -DataJson "{\"fetchRc\":!FETCH_RC!,\"localHead\":\"!LOCAL_HEAD!\",\"remoteHead\":\"!REMOTE_HEAD!\",\"mergeBase\":\"!MERGE_BASE!\",\"ahead\":!AHEAD!,\"behind\":!BEHIND!,\"rootCommit\":\"!ROOT_COMMIT!\",\"localCount\":!LOCAL_COUNT!,\"hasIso\":!HAS_ISO!,\"hasSample\":!HAS_SAMPLE!,\"unrelated\":!UNRELATED!}" -OutputFile "%TEMP%\sshd5014-fetch-out.txt"
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "B" -Location "publish.bat:pre-push-behind" -Message "Remote-ahead check" -DataJson "{\"behind\":!BEHIND!,\"ahead\":!AHEAD!}"
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "C" -Location "publish.bat:pre-push-pull" -Message "Publish script has no pull/rebase before push" -DataJson "{\"pullBeforePush\":false,\"behind\":!BEHIND!}"
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "D" -Location "publish.bat:pre-push-orphan" -Message "Orphan root check" -DataJson "{\"rootCommit\":\"!ROOT_COMMIT!\",\"localHead\":\"!LOCAL_HEAD!\",\"localCount\":!LOCAL_COUNT!,\"isOrphan\":!IS_ORPHAN!,\"unrelated\":!UNRELATED!}"
REM #endregion

echo ==^> Pushing to %REMOTE%/%BRANCH% as %GH_USER%
git -c credential.helper= push -u "!PUSH_URL!" "%BRANCH%" > "%TEMP%\sshd5014-push-out.txt" 2>&1
set "PUSH_RC=!ERRORLEVEL!"
type "%TEMP%\sshd5014-push-out.txt"
REM #region agent log
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "E" -Location "publish.bat:push" -Message "Push result" -DataJson "{\"exitCode\":!PUSH_RC!,\"behind\":!BEHIND!,\"mergeBase\":\"!MERGE_BASE!\",\"unrelated\":!UNRELATED!}" -OutputFile "%TEMP%\sshd5014-push-out.txt"
REM #endregion
if not "!PUSH_RC!"=="0" goto :fail

REM Clear secrets from this session
set "GH_TOKEN="
set "GH_TOKEN_ENC="
set "PUSH_URL="

REM #region agent log
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "A" -Location "publish.bat:success" -Message "Publish completed" -DataJson "{\"ok\":true}"
REM #endregion

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
REM #region agent log
powershell -NoProfile -File "%DEBUG_HELPER%" -LogPath "%DEBUG_LOG%" -HypothesisId "A" -Location "publish.bat:fail" -Message "Publish failed" -DataJson "{\"ok\":false}"
REM #endregion
echo.
echo Publish failed. Check username/token ^(repo scope needed^) and messages above.
echo If commit failed under OneDrive, ensure: git config windows.appendAtomically false
pause
exit /b 1
