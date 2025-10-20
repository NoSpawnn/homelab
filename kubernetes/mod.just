kubernetes_dir := justfile_dir() + '/kubernetes'

_default:
    @just --list k8s

[group("Bootstrap")]
create_sops_age_secret AGE_PRIVATE_KEY_FILE="":
    kubectl create namespace flux-system
    cat "{{ AGE_PRIVATE_KEY_FILE }}" | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin

# Run flux bootstrap for CLUSTER and create sops secret with AGE_PRIVATE_KEY_FILE
[group("Bootstrap")]
bootstrap CLUSTER="" AGE_PRIVATE_KEY_FILE="": (create_sops_age_secret AGE_PRIVATE_KEY_FILE)
    flux bootstrap git --url ssh://git@github.com/NoSpawnn/homelab.git --branch=master --private-key-file=./keys/key --path {{ kubernetes_dir }}/clusters/{{ CLUSTER }}
