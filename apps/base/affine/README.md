# AFFiNE

AFFiNE is a next-gen collaborative knowledge base that brings planning, sorting, and creating all together.

## Deployment Details

- **Namespace**: `affine`
- **Application Port**: `3010`
- **Domain**: `https://affine.rmtt.tech`
- **Routing**: Expose via Traefik `IngressRoute` with `cfresolver` certResolver.
- **Database**: CloudNative-PG cluster named `affine-db` running PostgreSQL 18. The `pgvector` extension is dynamically loaded using CNPG's **Image Volume Extensions** feature (`ghcr.io/cloudnative-pg/pgvector:0.8.4-18-bookworm`). Daily backups are scheduled at 2:00 AM to Backblaze B2 S3 storage.
- **Cache**: In-memory Redis server running in the same namespace.
- **Persistence**: 10Gi PV using `juicefs-oracle` storage class.

## Node Placement

The deployment has a node selector requiring scheduling on nodes located in the `oracle` region:
```yaml
nodeSelector:
  topology.kubernetes.io/region: oracle
```
