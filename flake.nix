{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        git-hooks-check = import ./git-hooks.nix { inherit pkgs git-hooks; };
      in
      {
        checks = {
          pre-commit-check = git-hooks-check;
        };

        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            kubectl
            kubectl-cnpg
            fluxcd
            jq
            sops
          ];
          shellHook = git-hooks-check.shellHook;
        };
      }
    );
}
