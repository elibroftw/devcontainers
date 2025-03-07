FROM almalinux:latest

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic packages
RUN dnf update -y && \
    dnf install -y \
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
    dnf-plugins-core

# Download the Microsoft RedHat repository package
RUN curl --proto '=https' --tlsv1.2 -sSL -O https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
# Register the Microsoft RedHat repository
RUN rpm -i packages-microsoft-prod.rpm
# Delete the downloaded package after installing
RUN rm packages-microsoft-prod.rpm
# Update package index files
RUN dnf update
# Install PowerShell 7+
RUN dnf install powershell -y

# Infisical repository
RUN curl --proto '=https' --tlsv1.2 -1sSLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.rpm.sh' | sh
# install infisical
RUN sudo dnf install infisical -y

# Install Nix with flakes enabled
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install Just command runner
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Set up environment
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"

# Verify installations

