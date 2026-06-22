# Agent Guidelines

Welcome to the infrastructure configuration repository. This project manages Kubernetes workloads via FluxCD.

## 1. Kubernetes Services

Tip: When manipulating the Kubernetes cluster, you must get permission from the user first. For sensitive data, put it into `values.yaml` and encrypt it with sops.

### Structure

The `apps/` directory uses a base/cluster split:

- `apps/base/<app>/` — app definitions (namespace, HelmRelease, database, ingress), shared and reusable across clusters.
- `apps/<cluster>/kustomization.yaml` — selects which base apps are deployed to that cluster by referencing `../base/<app>`. For example, `apps/public/` lists the apps deployed to the `public` cluster. Each cluster's Flux `Kustomization` (in `clusters/<cluster>/`) syncs the corresponding `apps/<cluster>/` path with `prune: true`.

### Adding a Service

1. Create a subdirectory under `apps/base/`.
2. Include a `README.md` documenting the service.
3. Always add a `nodeSelector` for application deployments.
4. Remind the user to update traefik and DNS.
5. When creating a `HelmRelease`, use the app folder name as both the release name and the namespace.
6. For `valuesFrom` in a `HelmRelease`, use `helm-values` as the name for the referenced `Secret` or `ConfigMap`.
7. Enable the app on a cluster by adding `- ../base/<app>` to `apps/<cluster>/kustomization.yaml`. An app is not deployed anywhere until it is listed in a cluster.

### Protecting Persistent Data Across App Removal

When an app is removed from Git (e.g. commented out in `apps/public/kustomization.yaml`), the parent `Kustomization` (`prune: true`) deletes every resource in the build output. **Deleting a Namespace cascades — Kubernetes wipes every resource inside it, bypassing all Helm and operator-level annotations.** To protect data across app removal, two layers are required:

**Layer 1 — Namespace** (always): add to `namespace.yaml`:

```yaml
metadata:
  annotations:
    kustomize.toolkit.fluxcd.io/prune: disabled
```

This stops the kustomize-controller from pruning the Namespace, preventing the cascade. The annotation is effective here because the kustomize-controller manages the Namespace directly (it is in the build output).

**Layer 2 — data resources**: the annotation depends on which controller manages the resource:

| Resource | Managed by | Annotation | Where to add it |
|----------|-----------|------------|-----------------|
| PVC (Helm chart) | helm-controller | `helm.sh/resource-policy: keep` | chart PVC template |
| PVC (Kustomization) | kustomize-controller | `kustomize.toolkit.fluxcd.io/prune: disabled` | the PVC manifest |
| CNPG `Cluster` + `ScheduledBackup` | kustomize-controller | `kustomize.toolkit.fluxcd.io/prune: disabled` | `db.yaml` |

> **Pitfall:** Do NOT put `kustomize.toolkit.fluxcd.io/prune: disabled` on a Helm-created PVC. The kustomize-controller does not track it (Helm created it), so the annotation is inert there. Only `helm.sh/resource-policy: keep` works for Helm PVCs, and it only protects against `helm uninstall` — which is why the Namespace (Layer 1) must also be protected.

### CloudNative-PG Databases

When creating a PostgreSQL database, use cloudnative-pg and ensure a scheduled backup for the cluster is created by default:

- Schedule the backup at 2am and keep 30 days of data.
- Enable WAL archiving.
- Create a secret named `cnpg-s3` for the S3 credentials (with keys `cnpg-s3-id`, `cnpg-s3-key`, and `region`) in the file `cnpg-s3.yaml`.
- Protect the `Cluster` and `ScheduledBackup` with `kustomize.toolkit.fluxcd.io/prune: disabled` (see [Protecting Persistent Data](#protecting-persistent-data-across-app-removal)).
