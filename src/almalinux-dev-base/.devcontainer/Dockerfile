FROM almalinux

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# wget
RUN dnf install -y wget
# yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# powershell can't be installed
# RUN dnf install -y krb5-libs libicu openssl-libs zlib
# RUN latest_release=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest) && \
#         rpmlink=$(echo "$latest_release" | arch=$(arch) yq -r '.assets[] | select(.name == ("*" + strenv(arch) + ".rpm")) | .browser_download_url') && \
#         dnf install -y $rpmlink

# Infisical repository
RUN curl --proto '=https' --tlsv1.2 -1sSLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.rpm.sh' | sh

# Update and install basic packages
RUN dnf update -y && \
    dnf install -y --allowerasing \
    git \
    python3 \
    python3-pip \
    curl \
    wget \
    sudo \
    which \
    procps \
    ca-certificates \
    gnupg \
    dnf-plugins-core \
    infisical

# Install Nix with flakes enabled
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

# Add nix to PATH
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

# Install Just command runner
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
