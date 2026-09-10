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
# Mirrors .azure-pipelines/build.yml's own recipe: `dotnet publish` (not
# `build`) on each of these three projects, then merge their publish/
# output directories. `build` alone leaves out transitive runtime deps
# that MiniInstaller lazily loads at runtime instead of referencing
# directly (e.g. Mono.Cecil.dll, pulled in through Celeste.Mod.mm's
# MonoMod.Patcher ProjectReference) -- publish's dependency closure
# picks those up, plain build doesn't.
STAGE_DIR="$BUILD_DIR/stage-main"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

for proj in NETCoreifier Celeste.Mod.mm MiniInstaller; do
  echo "publishing $proj..."
  dotnet publish "$proj/$proj.csproj" -c Release
  cp -r "$proj/bin/Release/net8.0/publish/." "$STAGE_DIR/"
done

echo "staging build output into $CELESTE_PATH..."
cp -r "$STAGE_DIR/." "$CELESTE_PATH/"

# MiniInstaller also expects the `lib-ext` submodule's native libraries
# (Steamworks.NET.dll, per-platform lib64-*/ folders, etc.) staged as
# CELESTE_PATH/everest-lib. Official releases bundle this alongside
# MiniInstaller; building from source has to do it by hand.
echo "staging lib-ext as $CELESTE_PATH/everest-lib..."
rm -rf "$CELESTE_PATH/everest-lib"
cp -r "$BUILD_DIR/Everest/lib-ext" "$CELESTE_PATH/everest-lib"

echo "running MiniInstaller against $CELESTE_PATH..."
# MiniInstaller itself now builds as a modern .NET (not Mono) app, with a
# self-contained native executable dropped alongside the dll -- run that
# directly rather than `mono MiniInstaller.dll` (throws a TypeLoadException
# on System.AppDomain, since that dll isn't a Mono/.NET-Framework assembly).
# NixOS has no system ICU by default, which the self-contained host wants
# purely for console text encoding -- run in globalization-invariant mode
# instead of pulling in libicu.
(cd "$CELESTE_PATH" && chmod +x ./MiniInstaller-linux && DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 ./MiniInstaller-linux)

if [ -f "$CELESTE_PATH/MMHOOK_Celeste.dll" ]; then
  echo "Everest installed: MMHOOK_Celeste.dll present in $CELESTE_PATH"
else
  echo "warning: MiniInstaller finished but MMHOOK_Celeste.dll wasn't found -- check its output above" >&2
fi
