@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "REPO_URL=https://github.com/AshbyCollado/AshbyWiki.git"
set "CHECK_ONLY=0"
set "TARGET_DIR="

:parse
if "%~1"=="" goto parsed
if /I "%~1"=="--check" (set "CHECK_ONLY=1" & shift & goto parse)
if /I "%~1"=="--help" goto usage
if /I "%~1"=="-h" goto usage
set "ARG=%~1"
if "!ARG:~0,2!"=="--" (echo Unknown option: %~1 & exit /b 2)
if defined TARGET_DIR (echo Only one target directory is supported.& exit /b 2)
set "TARGET_DIR=%~1"
shift
goto parse

:parsed
set "SCRIPT_DIR=%~dp0"
set "FAIL=0"
call :check_prerequisites
if "%CHECK_ONLY%"=="1" exit /b %FAIL%
if "%FAIL%"=="1" call :install_prerequisites
set "FAIL=0"
call :check_prerequisites
if "%FAIL%"=="1" (
  echo Prerequisites are incomplete. Authenticate with ^"gh auth login^" and install Node.js 22+/Obsidian, then rerun.
  exit /b 1
)

if defined TARGET_DIR (
  for %%D in ("%TARGET_DIR%") do set "REPO_DIR=%%~fD"
) else if exist "%SCRIPT_DIR%.git" (
  set "REPO_DIR=%SCRIPT_DIR%"
) else if exist "%CD%\.git" (
  set "REPO_DIR=%CD%"
) else (
  set "REPO_DIR=%CD%\AshbyWiki"
)
if exist "%REPO_DIR%\.git" goto repo_ready
if exist "%REPO_DIR%" (
  echo Target exists but is not a Git checkout: %REPO_DIR%
  exit /b 1
)
echo Cloning %REPO_URL% into %REPO_DIR%
git clone "%REPO_URL%" "%REPO_DIR%"
if errorlevel 1 exit /b 1

:repo_ready
if exist "%REPO_DIR%\package-lock.json" (
  pushd "%REPO_DIR%"
  call npm ci
  set "RC=!ERRORLEVEL!"
  popd
  exit /b !RC!
)
if exist "%REPO_DIR%\package.json" (
  echo No package-lock.json in %REPO_DIR%; refusing npm install. Create a lockfile, then rerun.
  exit /b 1
)
echo No package.json yet in %REPO_DIR%; prerequisite bootstrap is complete.
echo Setup complete: %REPO_DIR%
exit /b 0

:check_prerequisites
where git >nul 2>&1
if errorlevel 1 (echo MISSING: Git& set "FAIL=1") else (for /f "delims=" %%V in ('git --version 2^>nul') do echo OK: %%V)
where node >nul 2>&1
if errorlevel 1 (echo MISSING: Node.js 22 or newer& set "FAIL=1") else (
  for /f "delims=. tokens=1" %%V in ('node -p "process.versions.node" 2^>nul') do set "NODE_MAJOR=%%V"
  if not defined NODE_MAJOR (echo MISSING/OLD: Node.js 22 or newer& set "FAIL=1") else if !NODE_MAJOR! LSS 22 (echo MISSING/OLD: Node.js 22 or newer& set "FAIL=1") else (for /f "delims=" %%V in ('node --version') do echo OK: Node %%V)
)
where npm >nul 2>&1
if errorlevel 1 (echo MISSING: npm& set "FAIL=1") else (for /f "delims=" %%V in ('npm --version') do echo OK: npm %%V)
where gh >nul 2>&1
if errorlevel 1 (echo MISSING: GitHub CLI ^(gh^)& set "FAIL=1") else (
  set "GH_VERSION="
  for /f "delims=" %%V in ('gh --version 2^>nul') do if not defined GH_VERSION (echo OK: GitHub CLI %%V& set "GH_VERSION=1")
  gh auth status >nul 2>&1
  if errorlevel 1 (echo ACTION: run ^"gh auth login^"& set "FAIL=1") else echo OK: GitHub CLI authenticated
)
set "OBSIDIAN_OK=0"
where obsidian >nul 2>&1 && set "OBSIDIAN_OK=1"
if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\Obsidian\Obsidian.exe" set "OBSIDIAN_OK=1"
if defined ProgramFiles if exist "%ProgramFiles%\Obsidian\Obsidian.exe" set "OBSIDIAN_OK=1"
if "%OBSIDIAN_OK%"=="1" (echo OK: Obsidian) else (echo MISSING: Obsidian& set "FAIL=1")
exit /b 0

:install_prerequisites
where winget >nul 2>&1
if errorlevel 1 (
  echo Windows Package Manager ^(winget^) is required. Install it from the Microsoft Store, then rerun setup.bat.
  exit /b 1
)
where git >nul 2>&1 || winget install --id Git.Git --exact --accept-source-agreements --accept-package-agreements
call :is_node22
if errorlevel 1 winget install --id OpenJS.NodeJS.LTS --exact --accept-source-agreements --accept-package-agreements
where gh >nul 2>&1 || winget install --id GitHub.cli --exact --accept-source-agreements --accept-package-agreements
set "OBSIDIAN_OK=0"
if defined LOCALAPPDATA if exist "%LOCALAPPDATA%\Obsidian\Obsidian.exe" set "OBSIDIAN_OK=1"
if defined ProgramFiles if exist "%ProgramFiles%\Obsidian\Obsidian.exe" set "OBSIDIAN_OK=1"
if "%OBSIDIAN_OK%"=="0" winget install --id Obsidian.Obsidian --exact --accept-source-agreements --accept-package-agreements
echo Installation attempted. Open a new terminal if PATH changes are not visible.
exit /b 0

:is_node22
where node >nul 2>&1
if errorlevel 1 exit /b 1
set "NODE_MAJOR="
for /f "delims=. tokens=1" %%V in ('node -p "process.versions.node" 2^>nul') do set "NODE_MAJOR=%%V"
if not defined NODE_MAJOR exit /b 1
if !NODE_MAJOR! LSS 22 exit /b 1
exit /b 0

:usage
echo Usage: setup.bat [--check] [target-directory]
echo Without --check, install/check prerequisites, clone AshbyWiki outside a checkout, and run npm ci when package-lock.json exists.
exit /b 0
