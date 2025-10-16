# Homelab (to-be)

## Technologies

- [NoSpawnn/eepy_os](https://github.com/NoSpawnn/eepy_os) (customized Fedora CoreOS based OS)
- [Ignition](https://docs.fedoraproject.org/en-US/fedora-coreos/producing-ign/) (and [Butane](https://coreos.github.io/butane/)) for bootstrapping of hosts
- [SOPS](https://github.com/getsops/sops) (using [age](https://github.com/FiloSottile/age) keys) for encryption of secrets
- [k0s](https://k0sproject.io/) for kubernetes

## References/inspiration/docs/etc

- [What is the simplest way to apply an updated Ignition file? - Fedora Discussion](https://discussion.fedoraproject.org/t/what-is-the-simplest-way-to-apply-an-updated-ignition-file/112078/5)
- [barnabas/mediabarn](https://gitlab.com/barnix/mediabarn)

## Future plans/ideas

- Boot nodes with iPXE to FCOS
    - [netboot.xyz](https://netboot.xyz/)
    - Auto-ignition? https://docs.fedoraproject.org/en-US/fedora-coreos/live-booting/#_booting_via_ipxe
