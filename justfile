_default:
    @just --list

# Generate ignition file from butane config
ignite HOST="" BUTANE_DIR="./bootstrap/butane" IGNITION_DIR="./bootstrap/ignition":
    #!/usr/bin/env bash

    readonly BUTANE_DIR="{{ BUTANE_DIR }}"
    readonly IGNITION_DIR="{{ IGNITION_DIR }}"
    readonly HOST="{{ HOST }}"
    readonly OUT_FILE="$IGNITION_DIR/hosts/$HOST.ign"
    readonly IN_FILE="/butane/hosts/$HOST.bu"

    tag="butane"

    # Yes, this is kind of ugly, but its the prettiest I can get it at 2am
    podman build -f bootstrap/butane.containerfile -t $tag
    podman run --rm \
      -v ./bootstrap/butane:/butane:Z \
      -v ./bootstrap/ignition:/ignition:Z \
      -e HOST=$HOST \
      localhost/$tag \
      /bin/bash -c 'for f in $(find /butane/common -name "*.bu"); do
          ign_file=$(echo "$f" | sed -r "s|.*/(.*)\.bu|/ignition/common/\1.ign|");
          butane --strict "$f" > "$ign_file";
      done && butane --files-dir /ignition /butane/hosts/$HOST.bu > /ignition/hosts/$HOST.ign'

validate-ignition HOST="": (ignite HOST)
    podman run --pull=always --rm -i quay.io/coreos/ignition-validate:release - < "./bootstrap/ignition/hosts/{{ HOST }}.ign"

download-coreos PLATFORM="metal" FORMAT="iso" RELEASE="stable":
    #!/usr/bin/env bash

    PLATFORM="{{ PLATFORM }}"
    FORMAT="{{ FORMAT }}"
    RELEASE="{{ RELEASE }}"

    podman run --security-opt label=disable --pull=always --rm -v .:/data -w /data \
        quay.io/coreos/coreos-installer:release download -s "$RELEASE" -p "$PLATFORM" -f "$FORMAT"

    # Remove the signature file
    rm fedora-coreos-*.sig

mkpasswd:
    @# See: https://docs.fedoraproject.org/en-US/fedora-coreos/authentication/#_using_password_authentication
    podman run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt

coreos-vm HOST="": (ignite HOST)
    #!/usr/bin/env bash

    IGNITION_CONFIG="./bootstrap/ignition/hosts/{{ HOST }}.ign"
    IMAGE="coreos.qcow2"
    IGNITION_DEVICE_ARG="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"

    qemu-kvm -m 2048 -cpu host -nographic -snapshot \
      -drive "if=virtio,file=${IMAGE}" ${IGNITION_DEVICE_ARG} \
      -nic user,model=virtio,hostfwd=tcp::2222-:22
