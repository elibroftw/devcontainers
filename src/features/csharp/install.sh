#!/usr/bin/env bash
set -e

# CHANNEL is the `channel` option, passed in uppercased by the devcontainer CLI
DOTNET_CHANNEL="${CHANNEL:-LTS}"
DOTNET_INSTALL_DIR=/usr/local/share/dotnet

# The base image already installs the runtime for powershell, but into root's
# home where the remote user cannot reach it, so put the SDK somewhere shared
curl --proto '=https' --tlsv1.2 -sSfL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
chmod +x /tmp/dotnet-install.sh
/tmp/dotnet-install.sh --channel "$DOTNET_CHANNEL" --install-dir "$DOTNET_INSTALL_DIR"
rm /tmp/dotnet-install.sh

# dotnet-install.sh does not touch PATH, and the SDK is root-owned
ln -sf "$DOTNET_INSTALL_DIR/dotnet" /usr/local/bin/dotnet
chmod -R a+rX "$DOTNET_INSTALL_DIR"
