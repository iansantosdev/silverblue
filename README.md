# A Custom Fedora Silverblue Image &nbsp; [![build badge](https://github.com/iansantosdev/silverblue/actions/workflows/release.yml/badge.svg)](https://github.com/iansantosdev/silverblue/actions/workflows/release.yml)

This repository provides a custom OCI image built from Fedora Silverblue. It is designed to offer a tailored desktop experience with a focus on a minimal base system, sane defaults, and the latest open-source technologies.

This image is generated using the [BlueBuild](https://blue-build.org/) framework, which simplifies the process of creating and maintaining custom images.

## Key Features

- **Fedora Silverblue Base**: Built from the latest stable release of Fedora Silverblue, ensuring a robust and reliable foundation.
- **Curated Package Set**: Replaces many stock packages with Flatpak alternatives for a leaner, more maintainable base system.
- **Ready-to-go Experience**: Comes with RPM Fusion repositories, Flathub, and essential codecs pre-configured.
- **Enhanced Desktop Environment**: Includes a custom font set (JetBrains Mono Nerd Font) and a selection of quality-of-life GNOME extensions.
- **Developer Ready**: Pre-installs a variety of common development tools, container runtimes, and command-line utilities.
- **System Automation**: Features automated system and Flatpak updates, autologin, and other systemd-based services for convenience.

## Security Notes

This image is tuned for a personal workstation and intentionally favors convenience in a few places:

- GDM autologin is enabled for the first regular user found on the system.
- `doas` permits passwordless commands for members of the `wheel` group.
- Tailscale forwarding sysctls are enabled so the host can act as a subnet/router node.

Review these defaults before using the image on a shared, managed, or physically exposed machine.

## Desktop Defaults

Default Flatpaks are declared through Flatpak's native `preinstall.d` mechanism, installed per user on login, and validated against Flathub in CI. The GNOME favorites list also includes applications that may be provided later by dotfiles or manual Flatpak installs, such as VSCodium, Zed, Pods, Heroic, and Steam. Missing favorites are harmless but can show dead launchers until those applications are installed.

GNOME extensions are resolved from `extensions.gnome.org` during the image build, except Spotify Flatpak Panel, which is installed from the latest Codeberg release. The Firefox GNOME Theme updater always installs the latest commit from the upstream default branch.

## Provenance

- RTL8761BU firmware overrides live under `files/system/usr/lib/firmware/rtl_bt/` and are tracked in this repository so the image can carry the exact Bluetooth firmware/config payload it expects.
- `mergerfs` is installed from the upstream trapexit GitHub release URL declared in `recipes/silverblue.yml`.
- The Tailscale repository file is fetched from the upstream Tailscale Fedora repository URL declared in `recipes/silverblue.yml`.

## Development

Run the local validation suite before opening a pull request:

```bash
./scripts/validate.sh
```

The script validates the BlueBuild recipe, shell scripts, systemd units, dconf keyfiles, and GSettings overrides.

Custom systemd units use the `silverblue-` prefix and keep unit-only helpers under
`/usr/libexec/silverblue`. Unit enablement and masking are declared exclusively in
`recipes/silverblue.yml`; vendor units are customized with drop-ins.

## Installation

To rebase an existing Fedora Silverblue (or other atomic Fedora) installation to this image, follow the steps below.

1.  **Add the Signing Key**

    First, rebase to the unsigned image. This will install the required signing keys and repository configurations.

    ```bash
    rpm-ostree rebase ostree-unverified-registry:ghcr.io/iansantosdev/silverblue
    ```

2.  **Reboot**

    Reboot your system to apply the changes.

    ```bash
    systemctl reboot
    ```

3.  **Rebase to the Signed Image**

    Finally, rebase to the signed image to complete the installation.

    ```bash
    rpm-ostree rebase ostree-image-signed:registry:ghcr.io/iansantosdev/silverblue
    ```

4.  **Reboot Again**

    Reboot one last time to boot into your new desktop environment.

    ```bash
    systemctl reboot
    ```

The `latest` tag will always point to the most recent build based on the Fedora version specified in the [recipe](recipes/silverblue.yml).

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repository and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/iansantosdev/silverblue
```
