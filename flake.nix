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
            dotnet-sdk_8
            mono
            git
            curl
            unzip
            jq
          ];

          shellHook = ''
            export CELESTE_PATH="''${CELESTE_PATH:-${defaultCelestePath}}"
            if [ -f "$CELESTE_PATH/Celeste.exe" ]; then
              echo "celeste-d-ashpad devshell: CELESTE_PATH=$CELESTE_PATH (found)"
            else
              echo "celeste-d-ashpad devshell: CELESTE_PATH=$CELESTE_PATH (Celeste.exe NOT found here — export CELESTE_PATH to override)"
            fi
            if [ -f "$CELESTE_PATH/MMHOOK_Celeste.dll" ]; then
              echo "Everest: installed (MMHOOK_Celeste.dll present)"
            else
              echo "Everest: not installed yet — run scripts/install-everest.sh"
            fi
          '';
        };
      });
}
