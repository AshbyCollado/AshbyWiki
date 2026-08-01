#!/usr/bin/env bash
# Portable bootstrap for AshbyWiki. Run from any directory or from a checkout.
set -Eeuo pipefail

readonly REPO_URL="https://github.com/AshbyCollado/AshbyWiki.git"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CHECK_ONLY=0
TARGET_DIR=""

usage() {
  cat <<'EOF'
Usage: ./setup.sh [--check] [target-directory]

Without --check, install/check prerequisites, clone AshbyWiki when outside a
checkout, and run npm ci when a package-lock.json is present.
EOF
}

while (($#)); do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [[ -n "$TARGET_DIR" ]]; then echo "Only one target directory is supported." >&2; exit 2; fi
      TARGET_DIR="$1"
      ;;
  esac
  shift
done

command_exists() { command -v "$1" >/dev/null 2>&1; }
is_node22() {
  command_exists node || return 1
  local major
  major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
  [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 22 ))
}
has_obsidian() {
  command_exists obsidian && return 0
  [[ -x /usr/bin/obsidian || -x /snap/bin/obsidian || -d "/Applications/Obsidian.app" ]]
}
check_prerequisites() {
  local failed=0
  if command_exists git; then echo "OK: Git $(git --version)"; else echo "MISSING: Git"; failed=1; fi
  if is_node22; then echo "OK: Node $(node --version)"; else echo "MISSING/OLD: Node.js 22 or newer"; failed=1; fi
  if command_exists npm; then echo "OK: npm $(npm --version)"; else echo "MISSING: npm"; failed=1; fi
  if command_exists gh; then
    echo "OK: GitHub CLI $(gh --version | head -n 1)"
    if gh auth status >/dev/null 2>&1; then echo "OK: GitHub CLI authenticated"; else echo "ACTION: run 'gh auth login'"; failed=1; fi
  else echo "MISSING: GitHub CLI (gh)"; failed=1; fi
  if has_obsidian; then echo "OK: Obsidian"; else echo "MISSING: Obsidian"; failed=1; fi
  return "$failed"
}

sudo_cmd() { if [[ "$(id -u)" -eq 0 ]]; then command "$@"; else sudo "$@"; fi; }
install_linux() {
  local pm=""
  if command_exists apt-get; then pm=apt
  elif command_exists dnf; then pm=dnf
  elif command_exists pacman; then pm=pacman
  else
    echo "Unsupported Linux package manager. Install Git, Node.js 22+, npm, gh, and Obsidian manually:" >&2
    echo "https://git-scm.com/download/linux  https://nodejs.org/en/download  https://cli.github.com/  https://obsidian.md/download" >&2
    return 1
  fi
  case "$pm" in
    apt)
      sudo_cmd apt-get update
      sudo_cmd apt-get install -y git nodejs npm gh python3
      if command_exists snap; then sudo_cmd snap install obsidian --classic || true
      else echo "Install snapd, then run: sudo snap install obsidian --classic" >&2; fi ;;
    dnf)
      sudo_cmd dnf install -y git nodejs npm gh python3
      if command_exists snap; then sudo_cmd snap install obsidian --classic || true
      else echo "Install snapd, then run: sudo snap install obsidian --classic" >&2; fi ;;
    pacman)
      sudo_cmd pacman -Sy --needed --noconfirm git nodejs npm github-cli python
      if command_exists snap; then sudo_cmd snap install obsidian --classic || true
      else echo "Install Obsidian through your distro package manager: https://obsidian.md/download" >&2; fi ;;
  esac
}
install_prerequisites() {
  if [[ "$(uname -s)" == Darwin* ]]; then
    if ! command_exists brew; then echo "Homebrew is required: https://brew.sh/" >&2; return 1; fi
    command_exists git || brew install git
    if ! is_node22; then brew install node@22; brew link --overwrite --force node@22 || true; fi
    command_exists gh || brew install gh
    if ! has_obsidian; then brew install --cask obsidian; fi
  elif [[ "$(uname -s)" == Linux* ]]; then
    install_linux || return 1
  else
    echo "This script supports macOS and Linux. Use setup.bat on Windows." >&2
    return 1
  fi
}

if (( CHECK_ONLY )); then
  check_prerequisites
  exit $?
fi

install_prerequisites || { echo "Prerequisite installation failed; see the manual links above." >&2; exit 1; }
check_prerequisites || { echo "Prerequisites are incomplete. Authenticate with 'gh auth login' and install Node.js 22+/Obsidian, then rerun." >&2; exit 1; }

if [[ -n "$TARGET_DIR" ]]; then
  REPO_DIR="$(cd -- "$(dirname -- "$TARGET_DIR")" && pwd)/$(basename -- "$TARGET_DIR")"
elif [[ -d "$SCRIPT_DIR/.git" || -f "$SCRIPT_DIR/.git" ]]; then
  REPO_DIR="$SCRIPT_DIR"
elif [[ -d "$PWD/.git" || -f "$PWD/.git" ]]; then
  REPO_DIR="$PWD"
else
  REPO_DIR="$PWD/AshbyWiki"
fi

if [[ -d "$REPO_DIR/.git" || -f "$REPO_DIR/.git" ]]; then
  echo "Using checkout: $REPO_DIR"
elif [[ -e "$REPO_DIR" ]]; then
  echo "Target exists but is not a Git checkout: $REPO_DIR" >&2
  exit 1
else
  echo "Cloning $REPO_URL into $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

if [[ -f "$REPO_DIR/package-lock.json" ]]; then
  (cd "$REPO_DIR" && npm ci && bash scripts/install-obsidian-plugins.sh content)
elif [[ -f "$REPO_DIR/package.json" ]]; then
  echo "No package-lock.json in $REPO_DIR; refusing npm install. Create a lockfile, then rerun." >&2
  exit 1
else
  echo "No package.json yet in $REPO_DIR; prerequisite bootstrap is complete."
fi
echo "Setup complete: $REPO_DIR"
