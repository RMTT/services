{ pkgs, git-hooks }:
git-hooks.lib.${pkgs.system}.run {
  src = ./.;
  hooks = {
    sops-encrypted = {
      enable = true;
      name = "sops-encrypted";
      description = "Verify every file under secrets/ (except kustomization.yaml) has a sops metadata block";
      entry = "${pkgs.writeShellScript "check-sops-encrypted" ''
        set -uo pipefail
        status=0
        for f in "$@"; do
          if ! out=$(${pkgs.sops}/bin/sops filestatus "$f" 2>/dev/null); then
            echo "ERROR: $f could not be parsed by sops" >&2
            status=1
            continue
          fi
          if ! echo "$out" | ${pkgs.jq}/bin/jq -e '.encrypted == true' >/dev/null 2>&1; then
            echo "ERROR: $f is not sops-encrypted" >&2
            status=1
          fi
        done
        exit $status
      ''}";
      files = "(^|/)secrets/.+$";
      excludes = [ "kustomization\\.ya?ml$" ];
      language = "system";
      pass_filenames = true;
    };
  };
}
