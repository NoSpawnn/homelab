# Cluster/dev

- Development cluster, not tied to any specific hardware, but expected to run with K0s on bare metal

## Cluster specific stuff

- Ingress is under *.dev-cluster.local
    - Ingress is handled by [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main) exposed directly on port 80/443 on the host
    - Currently I manually add the entries to `/etc/hosts`, there's definitely a nicer way to do that...
- [openebs](https://github.com/openebs/openebs/tree/develop) ([Helm chart](https://github.com/openebs/openebs/tree/develop/charts))
    - K0s doesn't provide a storage class by default
    - I disable the ZFS and mayastor engines
    - Full values at [./openebs/release.yaml](./openebs/release.yaml)
