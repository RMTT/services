# lldap

[LLDAP](https://github.com/lldap/lldap) is a lightweight LDAP server with a web
administration UI.

## Details

- **Image:** `lldap/lldap` (chart `appVersion`), see `charts/lldap`.
- **Storage:** SQLite database persisted on a `/data` PVC (`lldap-pvc`). The PVC
  carries `helm.sh/resource-policy: keep` so it survives `helm uninstall`; the
  `lldap` Namespace is annotated `kustomize.toolkit.fluxcd.io/prune: disabled`
  so it survives app removal from a cluster.
- **Ports:** web UI `17170`, LDAP `3890`, both reachable cluster-internally on
  the `lldap` Service (no `IngressRoute`).
- **Environment:** all `LLDAP_*` env vars (including `LLDAP_JWT_SECRET`,
  `LLDAP_KEY_SEED`, the admin password `LLDAP_LDAP_USER_PASS`, the LDAP base DN
  and `LLDAP_HTTP_URL`) are provided to the chart via `valuesFrom` from the
  sops-encrypted `secrets/lldap/helm-values.yaml` Secret.

## TODO on first deploy

- Log in to the web UI as `admin` using the password from the encrypted values
  and change it if needed.
