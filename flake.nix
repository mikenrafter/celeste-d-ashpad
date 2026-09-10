{
  description = "Celeste Everest mod: fixes the same-key dash+direction race (celeste-d-ashpad)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Default Steam install location for this machine. Override by
        # exporting CELESTE_PATH before entering the shell if it differs.
        defaultCelestePath = "/home/v0id/Games/Steam/steamapps/common/Celeste";
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            dotnet-sdk_9
            mono
            git
            curl
            unzip
            jq
          ];

          shellHook = ''
            export CELESTE_PATH="''${CELESTE_PATH:-${defaultCelestePath}}"
            # Celeste.exe pre-Everest, Celeste.dll once MiniInstaller has
            # patched it onto modern .NET -- either means the dir is right.
            if [ -f "$CELESTE_PATH/Celeste.exe" ] || [ -f "$CELESTE_PATH/Celeste.dll" ]; then
              echo "celeste-d-ashpad devshell: CELESTE_PATH=$CELESTE_PATH (found)"
            else
              echo "celeste-d-ashpad devshell: CELESTE_PATH=$CELESTE_PATH (Celeste not found here — export CELESTE_PATH to override)"
            fi
            if [ -f "$CELESTE_PATH/MMHOOK_Celeste.dll" ]; then
              echo "Everest: installed (MMHOOK_Celeste.dll present)"
            else
              echo "Everest: not installed yet — run scripts/install-everest.sh"
            fi
            if [ -L "$CELESTE_PATH/Mods/CelesteDashpad" ]; then
              echo "Mod: symlinked into CELESTE_PATH/Mods/CelesteDashpad -- 'dotnet build' here updates it in place"
            else
              echo "Mod: not deployed -- ln -s \$PWD \"\$CELESTE_PATH/Mods/CelesteDashpad\""
            fi
          '';
        };
      });
}
