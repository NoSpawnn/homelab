# Literally just a container with butane installed lol

FROM fedora:42

VOLUME [ "/butane" "/ignition" ]

RUN dnf update -y && dnf install -y butane
