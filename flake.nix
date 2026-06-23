{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      hooks-git =
        system:
        git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            sops-encrypted = {
              enable = true;
              name = "sops-encrypted";
              description = "Verify every file under secrets/ (except kustomization.yaml) has a sops metadata block";
              entry = "${./scripts/check-sops-encrypted.sh}";
              files = "(^|/)secrets/.+$";
              excludes = [ "kustomization\\.ya?ml$" ];
              language = "system";
              pass_filenames = true;
            };
          };
        };
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              kubectl
              kubectl-cnpg
              fluxcd
              jq
              sops
            ];
            shellHook = ''
              ${(hooks-git system).shellHook}
            '';
          };
        }
      );
    };
}
