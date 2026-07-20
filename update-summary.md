# Update Summary
* `infra/public/juicefs-csi-instance.yaml`: Updated `redis` chart from `27.0.10` to `27.0.15`.
  - [bitnami/redis] bugfix: use TLS port on readiness probes when TLS is enabled (#36463)
  - [bitnami/redis] feat: add support for sync checks on replica nodes with sentinel (#36461)
  - [bitnami/redis] Add support to redis master service with useHostnames false (#35536)
  - [bitnami/redis] Fix automatic sentinel failover not triggering on graceful shutdown (#36362)
  - [bitnami/redis] Avoid eager evaluation of ternary when resolving user secrets (#36265)
