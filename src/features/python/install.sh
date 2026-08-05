#!/usr/bin/env bash
set -e

# VERSION is the `version` option, passed in uppercased by the devcontainer CLI.
# Blank means uv only, no managed interpreter.
PYTHON_VERSION="${VERSION:-}"

# UV_INSTALL_DIR keeps uv out of root's home so every user can run it
curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

if [ -n "$PYTHON_VERSION" ]; then
    # Feature scripts run as root, so install system-wide instead of hiding the
    # interpreter in root's ~/.local where the remote user cannot reach it
    export UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python
    export UV_PYTHON_BIN_DIR=/usr/local/bin
    uv python install "$PYTHON_VERSION"

    # uv creates the install dir root-owned, so let every user read and execute it
    chmod -R a+rX "$UV_PYTHON_INSTALL_DIR"
fi
