#!/usr/bin/env bash
# Builds Everest (the Celeste mod loader) from source and installs it into
# CELESTE_PATH, patching the game in place (MiniInstaller backs up the
# original Celeste.exe itself, but Steam can also re-verify/reinstall the
# game from scratch if anything goes wrong).
set -euo pipefail

CELESTE_PATH="${CELESTE_PATH:-/home/v0id/Games/Steam/steamapps/common/Celeste}"
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.everest-build"

if [ ! -f "$CELESTE_PATH/Celeste.exe" ]; then
  echo "error: Celeste.exe not found at CELESTE_PATH=$CELESTE_PATH" >&2
  exit 1
fi

command -v dotnet >/dev/null || { echo "error: dotnet not on PATH (enter the flake devshell: nix develop)" >&2; exit 1; }
command -v mono >/dev/null || { echo "error: mono not on PATH (enter the flake devshell: nix develop)" >&2; exit 1; }
command -v git >/dev/null || { echo "error: git not on PATH" >&2; exit 1; }

mkdir -p "$BUILD_DIR"

if [ ! -d "$BUILD_DIR/Everest/.git" ]; then
  echo "cloning EverestAPI/Everest..."
  git clone --depth 1 --recurse-submodules https://github.com/EverestAPI/Everest.git "$BUILD_DIR/Everest"
else
  echo "Everest source already present at $BUILD_DIR/Everest, pulling latest..."
  git -C "$BUILD_DIR/Everest" pull --ff-only
fi

cd "$BUILD_DIR/Everest"

echo "building Everest (Release)..."
dotnet build Everest.sln -c Release

MINI_INSTALLER_OUT="$(find . -type f -iname 'MiniInstaller.dll' -path '*Release*' | head -n1)"
if [ -z "$MINI_INSTALLER_OUT" ]; then
  echo "error: could not find built MiniInstaller.dll under $BUILD_DIR/Everest -- inspect the build output above" >&2
  exit 1
fi
MINI_INSTALLER_DIR="$(dirname "$MINI_INSTALLER_OUT")"

echo "staging build output into $CELESTE_PATH..."
cp -r "$MINI_INSTALLER_DIR"/. "$CELESTE_PATH/"

echo "running MiniInstaller against $CELESTE_PATH..."
(cd "$CELESTE_PATH" && mono MiniInstaller.dll)

if [ -f "$CELESTE_PATH/MMHOOK_Celeste.dll" ]; then
  echo "Everest installed: MMHOOK_Celeste.dll present in $CELESTE_PATH"
else
  echo "warning: MiniInstaller finished but MMHOOK_Celeste.dll wasn't found -- check its output above" >&2
fi
