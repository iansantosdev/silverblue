# A Custom Fedora Silverblue Image &nbsp; [![build badge](https://github.com/iansantosdev/silverblue/actions/workflows/release.yml/badge.svg)](https://github.com/iansantosdev/silverblue/actions/workflows/release.yml)

This repository provides a custom OCI image built from Fedora Silverblue. It is designed to offer a tailored desktop experience with a focus on a minimal base system, sane defaults, and the latest open-source technologies.

This image is generated using the [BlueBuild](https://blue-build.org/) framework, which simplifies the process of creating and maintaining custom images.

## Key Features

-   **Fedora Silverblue Base**: Built from the latest stable release of Fedora Silverblue, ensuring a robust and reliable foundation.
-   **Curated Package Set**: Replaces many stock packages with Flatpak alternatives for a leaner, more maintainable base system.
-   **Ready-to-go Experience**: Comes with RPM Fusion repositories, Flathub, and essential codecs pre-configured.
-   **Enhanced Desktop Environment**: Includes a custom font set (JetBrains Mono Nerd Font) and a selection of quality-of-life GNOME extensions.
-   **Developer Ready**: Pre-installs a variety of common development tools, container runtimes, and command-line utilities.
-   **System Automation**: Features automated system and Flatpak updates, autologin, and other systemd-based services for convenience.

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
