@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "DRY_RUN=0"
if /I "%~1"=="--dry-run" (set "DRY_RUN=1" & shift)
if not "%~1"=="" if /I not "%~1"=="--help" (echo Unknown option: %~1& exit /b 2)
if /I "%~1"=="--help" goto usage
git rev-parse --show-toplevel >nul 2>&1
if errorlevel 1 (echo Not inside a Git checkout.& exit /b 1)
for /f "delims=" %%R in ('git rev-parse --show-toplevel') do set "ROOT=%%R"
pushd "%ROOT%"
for /f "delims=" %%B in ('git symbolic-ref --quiet --short HEAD 2^>nul') do set "BRANCH=%%B"
if not "%BRANCH%"=="main" (echo Refusing to sync branch ^"%BRANCH%^"; checkout main first.& popd& exit /b 1)
for /f "delims=" %%P in ('git rev-parse --git-path rebase-merge') do set "REBASE_MERGE=%%P"
for /f "delims=" %%P in ('git rev-parse --git-path rebase-apply') do set "REBASE_APPLY=%%P"
if exist "%REBASE_MERGE%" (echo A rebase is already in progress. Resolve it or run: git rebase --abort& popd& exit /b 1)
if exist "%REBASE_APPLY%" (echo A rebase is already in progress. Resolve it or run: git rebase --abort& popd& exit /b 1)
git diff --name-only --diff-filter=U | findstr /R /C:"." >nul
if not errorlevel 1 (echo Unresolved merge conflicts are present. Resolve them before syncing.& popd& exit /b 1)
if "%DRY_RUN%"=="1" (
  echo Dry run: would stage all non-ignored files, commit if changed, rebase origin/main, and push origin main.
  git status --short
  popd
  exit /b 0
)
git remote get-url origin >nul 2>&1
if errorlevel 1 (echo Remote ^"origin^" is not configured.& popd& exit /b 1)
git add --all
git diff --cached --quiet
if not errorlevel 1 (echo No changes to sync.& popd& exit /b 0)
for /f "delims=" %%T in ('powershell -NoProfile -Command "[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')"') do set "STAMP=%%T"
git commit -m "Auto-sync: !STAMP!"
if errorlevel 1 (echo Commit failed; nothing was pushed.& popd& exit /b 1)
git fetch origin main
if errorlevel 1 (echo Fetch failed; nothing was pushed. Check authentication/network.& popd& exit /b 1)
git rebase origin/main
if errorlevel 1 (echo Rebase conflict; nothing was pushed. Resolve, run ^"git rebase --continue^", or abort with ^"git rebase --abort^".& popd& exit /b 1)
git push origin main
if errorlevel 1 (echo Push failed. Check authentication/network; local commits remain intact.& popd& exit /b 1)
echo Sync complete.
popd
exit /b 0
:usage
echo Usage: sync.bat [--dry-run]
exit /b 0
