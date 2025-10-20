# clusters/dev

- Development cluster, run using [kind](https://kind.sigs.k8s.io/)

## Cluster specific stuff

- Ingress is under *.dev-cluster.local
    - Handled by [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main) using [kubernetes-sigs/cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind)
    - Currently I manually add the entries to `/etc/hosts`, there's definitely a nicer way to do that...
    - [openebs](https://github.com/openebs/openebs/tree/develop) ([Helm chart](https://github.com/openebs/openebs/tree/develop/charts))
        - k0s doesn't provide a storage class by default
        - ZFS and mayastor engines are disabled
        - Full values at [./openebs/release.yaml](./openebs/release.yaml)
