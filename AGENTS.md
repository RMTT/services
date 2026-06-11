# Agent Guidelines

Welcome to the infrastructure configuration repository. This project manages Kubernetes workloads via FluxCD.

## 1. Kubernetes Services

Tip: When manipulating kubernetes cluster, must get granted from user first. For sensitive data, put it into values.yaml and encryt it with sops.

- **Structure:** The `apps/` directory is the root for Kubernetes service definitions. Each subdirectory represents a logical service (e.g., `postgresql/`, `ollama/`).
- **Adding Services:**
  1. Create a subdirectory under `apps/`.
  2. Include a `README.md` documenting the service.
  3. Always add a nodeSelector for application deployments.
  4. Remind user to update traefik and dns.
  5. When creating a `HelmRelease`, use the folder name as the release name. For the namespace name, use the parent folder's name; however, if the parent folder is `apps/`, use the current folder's name as the namespace.
  6. For `valuesFrom` in a `HelmRelease`, use `helm-values` as the name for the referenced `Secret` or `ConfigMap`.
