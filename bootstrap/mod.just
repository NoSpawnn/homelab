bootstrap_dir := justfile_dir() + '/bootstrap'

_default:
    @just --list coreos

# Create ignition file through pyromaniac for a given host
[group("Pyromaniac/Ignition")]
ignite HOST="":
    podman run --rm --interactive --security-opt label=disable --publish 8000:8000 \
        --volume ./pyromaniac:/spec:ro \
        ghcr.io/salatfreak/pyromaniac:latest --pretty main.pyro {{ HOST }} > {{ bootstrap_dir }}/ignition/{{ HOST }}.ign

# Validate ignition file
[group("Pyromaniac/Ignition")]
validate-ignition FILE="":
    podman run --pull=always --rm -i quay.io/coreos/ignition-validate:release - < "{{ FILE }}"

# Download CoreOS for PLATFORM as FORMAT
[group("Pyromaniac/Ignition")]
download PLATFORM="metal" FORMAT="iso" RELEASE="stable":
    #!/usr/bin/env bash

    PLATFORM="{{ PLATFORM }}"
    FORMAT="{{ FORMAT }}"
    RELEASE="{{ RELEASE }}"

    file=$(podman run --security-opt label=disable --pull=always --rm -v .:/data -w /data \
        quay.io/coreos/coreos-installer:release download -s "$RELEASE" -p "$PLATFORM" -f "$FORMAT" | tail -n 1)

    version=$(echo "$file" | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([^.]+)\.([^.]+)\..*/\1/')
    platform=$(echo "$file" | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([^.]+)\.([^.]+)\..*/\2/')
    arch=$(echo "$file" | sed -E 's/.*-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([^.]+)\.([^.]+)\..*/\3/')

    echo "Got CoreOS $version for $platform $arch"

    mv $file coreos.$FORMAT

    case $FORMAT in
        "qcow2.xz")
            xz --decompress coreos.qcow2.xz
        ;;
    esac

    # Remove the signature file
    rm fedora-coreos-*.sig || true

[group("CoreOS")]
# Generate yescrypt password hash
mkpasswd:
    # See: https://docs.fedoraproject.org/en-US/fedora-coreos/authentication/#_using_password_authentication
    podman run -ti --rm quay.io/coreos/mkpasswd --method yescrypt

[group("CoreOS")]
# Launch qemu VM for HOST with automatic ignition
vm HOST="": (ignite HOST) #(download "qemu" "qcow2.xz" "stable")
    #!/usr/bin/env bash

    IGNITION_CONFIG="{{ bootstrap_dir }}/ignition/{{ HOST }}.ign"
    IMAGE="coreos.qcow2"
    IGNITION_DEVICE_ARG="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"

    qemu-kvm -m 2048 -cpu host -nographic -snapshot \
      -drive "if=virtio,file=${IMAGE}" ${IGNITION_DEVICE_ARG} \
      -nic user,model=virtio,hostfwd=tcp::2222-:22
