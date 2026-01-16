{
  description = "A Nix-flake for basic python app development using uv";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # The following may not be needed since it is a standard flake registry
    # and so we can just refer to flake-utils without it
    # See https://zero-to-nix.com/concepts/flakes#registries
    # However we may need to 'follow' the nixpkgs version above?
    # flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs_unstable,
      flake-utils,
    }:
    # see https://github.com/numtide/flake-utils#eachdefaultsystem--system---attrs
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [ ];
        };
        pkgs_unstable = import nixpkgs_unstable {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [ ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs_unstable; [
            uv
            cacert
          ];

          # Ensure uv and Python see the CA bundle
          # SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          REQUESTS_CA_BUNDLE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          UV_SYSTEM_PYTHON = 1;

          shellHook = ''
            unset PYTHONPATH

            # Bridge Nix -> standard SSL variable
            export SSL_CERT_FILE="$NIX_SSL_CERT_FILE"

            [ -d .venv ] || uv sync
            . .venv/bin/activate
          '';
        };
      }
    );
}
