FROM almalinux

# see:
# buildpack-deps:nobel-curl https://github.com/docker-library/buildpack-deps/blob/master/ubuntu/noble/curl/Dockerfile
# base-ubuntu https://github.com/devcontainers/images/blob/main/src/base-ubuntu/.devcontainer/Dockerfile

# Infisical repository
# Install buildpack-deps equivalent
# Install useful packages
RUN curl --proto '=https' --tlsv1.2 -1sSLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.rpm.sh' | sh && \
    dnf update -y && \
    dnf install -y --allowerasing \
    ca-certificates curl gnupg2 wget tzdata \
    python3 \
    python3-pip \
    procps \
    dnf-plugins-core \
    infisical

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# powershell can't be installed
# RUN dnf install -y krb5-libs libicu openssl-libs zlib
# RUN latest_release=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest) && \
#         rpmlink=$(echo "$latest_release" | arch=$(arch) yq -r '.assets[] | select(.name == ("*" + strenv(arch) + ".rpm")) | .browser_download_url') && \
#         dnf install -y $rpmlink

# Install Nix with flakes enabled
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

# Add nix to PATH
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

# Install Just command runner
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
