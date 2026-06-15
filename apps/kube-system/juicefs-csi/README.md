# JuiceFS CSI Driver

This directory deploys the [JuiceFS CSI Driver](https://github.com/juicedata/juicefs-csi-driver) via FluxCD.

JuiceFS is a distributed POSIX file system built on top of Redis and S3. The CSI driver allows JuiceFS volumes to be used seamlessly in Kubernetes.

## Configuration
- Helm Chart Repository: https://juicedata.github.io/charts/
- Namespace: `kube-system`
- The `controller` component uses a nodeSelector to run specifically on `homeserver` (the node labels), while the `node` (DaemonSet) will run on all nodes where mounts are requested.
