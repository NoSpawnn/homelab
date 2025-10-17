bootstrap_dir := justfile_dir() + '/bootstrap'

_default:
    @just --list coreos

ignite HOST="" BUTANE_DIR="" IGNITION_DIR="":
    #!/usr/bin/env bash

    BOOTSTRAP_DIR="{{ bootstrap_dir }}"
    BUTANE_DIR="$BOOTSTRAP_DIR/butane"
    IGNITION_DIR="$BOOTSTRAP_DIR/ignition"
    HOST="{{ HOST }}"
    OUT_FILE="$IGNITION_DIR/hosts/$HOST.ign"
    IN_FILE="/butane/hosts/$HOST.bu"

    tag="butane"

    # Yes, this is kind of ugly, but its the prettiest I can get it at 2am
    podman build -f $BOOTSTRAP_DIR/butane.containerfile -t $tag
    podman run --rm \
      -v $BOOTSTRAP_DIR/butane:/butane:Z \
      -v $BOOTSTRAP_DIR/ignition:/ignition:Z \
      -e HOST=$HOST \
      localhost/$tag \
      /bin/bash -c 'for f in $(find /butane/common -name "*.bu"); do
          ign_file=$(echo "$f" | sed -r "s|.*/(.*)\.bu|/ignition/common/\1.ign|");
          butane --strict "$f" --files-dir /ignition --strict --pretty > "$ign_file";
      done && butane --files-dir /ignition --strict --pretty /butane/hosts/$HOST.bu > /ignition/hosts/$HOST.ign'

validate-ignition HOST="": (ignite HOST)
    podman run --pull=always --rm -i quay.io/coreos/ignition-validate:release - < "{{ bootstrap_dir }}/ignition/hosts/{{ HOST }}.ign"

get-iso PLATFORM="metal" FORMAT="iso" RELEASE="stable":
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

mkpasswd:
    # See: https://docs.fedoraproject.org/en-US/fedora-coreos/authentication/#_using_password_authentication
    podman run -ti --rm quay.io/coreos/mkpasswd --method yescrypt

vm HOST="": (ignite HOST) #(get-iso "qemu" "qcow2.xz" "stable")
    #!/usr/bin/env bash

    IGNITION_CONFIG="{{ bootstrap_dir }}/ignition/hosts/{{ HOST }}.ign"
    IMAGE="coreos.qcow2"
    IGNITION_DEVICE_ARG="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"

    qemu-kvm -m 2048 -cpu host -nographic -snapshot \
      -drive "if=virtio,file=${IMAGE}" ${IGNITION_DEVICE_ARG} \
      -nic user,model=virtio,hostfwd=tcp::2222-:22
