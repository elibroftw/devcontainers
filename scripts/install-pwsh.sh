#!/usr/bin/env bash

dnf install -y wget
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
sudo chmod +x ./dotnet-install.sh
./dotnet-install.sh --version latest --runtime dotnet
rm ./dotnet-install.sh

dnf install -y krb5-libs libicu openssl-libs zlib
# When I use dnf, I get this:
# Problem: conflicting requests
#   - nothing provides krb5 needed by powershell-7.5.0-1.cm.aarch64 from @commandline
# we can force rpm to ignore dependencies, which seems to work
latest_release=$(curl -s https://api.github.com/repos/PowerShell/PowerShell/releases/latest) && \
    rpmlink=$(echo "$latest_release" | arch=$(arch) yq -r '[.assets[] | select(.name == ("*" + strenv(arch) + ".rpm")) | .browser_download_url][0]') && \
    rpm -Uvh --nodeps $rpmlink
