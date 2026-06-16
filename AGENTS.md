# Agent Guidelines

Welcome to the infrastructure configuration repository. This project manages Kubernetes workloads via FluxCD.

## 1. Kubernetes Services

Tip: When manipulating kubernetes cluster, must get granted from user first. For sensitive data, put it into values.yaml and encryt it with sops.

- **Structure:** The `apps/` directory is the root for Kubernetes service definitions. Each subdirectory represents a logical service (e.g., `postgresql/`).
- **Adding Services:**
  1. Create a subdirectory under `apps/`.
  2. Include a `README.md` documenting the service.
  3. Always add a nodeSelector for application deployments.
  4. Remind user to update traefik and dns.
  5. When creating a `HelmRelease`, use the folder name as the release name. For the namespace name, use the parent folder's name; however, if the parent folder is `apps/`, use the current folder's name as the namespace.
  6. For `valuesFrom` in a `HelmRelease`, use `helm-values` as the name for the referenced `Secret` or `ConfigMap`.
  7. When creating a PostgreSQL database, use cloudnative-pg and ensure a scheduled backup for the cluster is created by default. Schedule the backup at 2am and keep 30 days of data. Also, enable WAL archiving. In the backup configuration, use S3 storage with the endpoint `http://nas.infra.rmtt.host:30188` as the backend, and create a secret named `cnpg-s3` for the S3 credentials (with keys `cnpg-s3-id`, `cnpg-s3-key`, and `region`) in the file `cnpg-s3.yaml`.
  8. When configuring JuiceFS, use S3 storage with the endpoint `http://nas.infra.rmtt.host:30188` as the object storage backend.
