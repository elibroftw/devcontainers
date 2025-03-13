ARG VARIANT="latest"
FROM almalinux:${VARIANT}

    # Add Infisical repository
RUN curl --proto '=https' --tlsv1.2 -1sSLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.rpm.sh' | sh && \
    dnf install -y epel-release && \
    dnf install -y elrepo-release && \
    # Install useful packages
    dnf update -y && \
    dnf install -y --allowerasing \
    # buildpack-deps equivalent
    ca-certificates curl gnupg2 wget tzdata \
    # remoteUser support
    shadow sudo \
    python3 \
    python3-pip \
    procps \
    dnf-plugins-core \
    git \
    infisical \
    ansible

# https://docs.fedoraproject.org/en-US/epel/getting-started/
RUN dnf config-manager --set-enabled crb

# Symlink vim to vi
RUN ln -s /usr/bin/vim /usr/bin/vi

# Install yq
RUN wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# Install Just command runner
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Install nix
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
    --extra-conf "sandbox = false" \
    --extra-conf "filter-syscalls = false" \
    --init none \
    --no-confirm
ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"
RUN nix run nixpkgs#hello

# Install powershell
RUN dnf install -y krb5-libs libicu openssl-libs zlib
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh && \
    chmod +x ./dotnet-install.sh && \
    ./dotnet-install.sh --version latest --runtime dotnet && \
    rm ./dotnet-install.sh
# When I use dnf, I get this:
# Problem: conflicting requests
#   - nothing provides krb5 needed by powershell-7.5.0-1.cm.aarch64 from @commandline
# We can force rpm to ignore this error, which seems to work
RUN latest_release=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest) && \
    rpmlink=$(echo "$latest_release" | arch=$(arch) yq -r '[.assets[] | select(.name == ("*" + strenv(arch) + ".rpm")) | .browser_download_url][0]') && \
    rpm -Uvh --nodeps  $rpmlink

# Create the user
# https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_change-the-uidgid-of-an-existing-container-user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support.
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# persist bash history
# user instructions: https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory \
  && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"
