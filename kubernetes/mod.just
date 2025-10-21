kubernetes_dir := justfile_dir() + "/kubernetes"

_default:
    @just --list k8s

[group("Bootstrap")]
[no-cd]
create_sops_age_secret AGE_PRIVATE_KEY_FILE="":
    kubectl create namespace flux-system
    cat "{{ AGE_PRIVATE_KEY_FILE }}" | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin

# Run flux bootstrap for CLUSTER and create sops secret with AGE_PRIVATE_KEY_FILE
[group("Bootstrap")]
[no-cd]
bootstrap CLUSTER="" AGE_PRIVATE_KEY_FILE="": (create_sops_age_secret AGE_PRIVATE_KEY_FILE)
    flux bootstrap git --url ssh://git@github.com/NoSpawnn/homelab.git --branch=master --private-key-file=./keys/key --path ./kubernetes/clusters/{{ CLUSTER }}

# Create dev cluster
[group("Dev")]
dev-cluster-spawn:
    kind create cluster --config ./clusters/dev/kind.yaml

# Delete dev cluster
[group("Dev")]
dev-cluster-del:
    kind delete cluster --name homelab-dev-cluster

# Create a new app
new-app NAME="" CLUSTER="dev":
    #!/usr/bin/env bash

    NAME="{{ NAME }}"
    CLUSTER="{{ CLUSTER }}"

    declare -A folder_map=(
        [infra]="infra"
        [observability]="observability"
        [service]="services"
    )

    PS3="Select app type: "
    select T in "${!folder_map[@]}"; do
        if [[ -n "$T" ]]; then
            TYPE="$T"
            BASE_RELPATH="apps/base/${folder_map[$T]}/$NAME"
            APP_RELPATH="apps/$CLUSTER/${folder_map[$T]}/$NAME"
            break
        else
            echo "Invalid selection."
        fi
    done

    BASE_DIR="{{ kubernetes_dir }}/$BASE_RELPATH"
    APP_DIR="{{ kubernetes_dir }}/$APP_RELPATH"

    mkdir "$BASE_DIR"
    mkdir "$APP_DIR"
    mkdir "$APP_DIR/app"

    cat <<EOF > "$BASE_DIR/kustomization.yaml"
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
      - repository.yaml
      - release.yaml
    EOF

    cat <<EOF > "$BASE_DIR/repository.yaml"
    # yaml-language-server: \$schema=https://kubernetes-schemas.pages.dev/source.toolkit.fluxcd.io/helmrepository_v1.json

    apiVersion: source.toolkit.fluxcd.io/v1
    kind: HelmRepository
    metadata:
      name: $NAME-repo
    spec:
      interval: 5m
      url:
    EOF

    cat <<EOF > "$BASE_DIR/release.yaml"
    # yaml-language-server: \$schema=https://kubernetes-schemas.pages.dev/helm.toolkit.fluxcd.io/helmrelease_v2.json
    #

    apiVersion: helm.toolkit.fluxcd.io/v2
    kind: HelmRelease

    metadata:
      name: $NAME

    spec:
      releaseName: $NAME
      chart:
        spec:
          chart:
          sourceRef:
            kind: HelmRepository
            name:
      interval: 50m
    EOF

    cat <<EOF > "$APP_DIR/app.yaml"
    # yaml-language-server: \$schema=https://kubernetes-schemas.pages.dev/kustomize.toolkit.fluxcd.io/kustomization_v1.json

    apiVersion: kustomize.toolkit.fluxcd.io/v1
    kind: Kustomization
    metadata:
      name: $NAME
      namespace: flux-system
    spec:
      interval: 10m0s
      sourceRef:
        kind: GitRepository
        name: flux-system
      path: ./kubernetes/$RELPATH
      prune: true
      wait: true
      timeout: 5m0s
    EOF

    cat <<EOF > "$APP_DIR/app/kustomization.yaml"
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    namespace: $NAME

    resources:
      - namespace.yaml
      - ../../../../base/$TYPE/$NAME
    EOF

    cat <<EOF > "$APP_DIR/app/namespace.yaml"
    apiVersion: v1
    kind: Namespace
    metadata:
      name: $NAME
    EOF
