#!/usr/bin/env bash
set -e

# The native installer is per-user by design: it installs into $HOME/.local/bin
# and refuses to run under sudo, so run it as the remote user rather than root.
# It ships its own binary, so this does not depend on the frontend feature's node.
su - "$_REMOTE_USER" -c '
    curl --proto "=https" --tlsv1.2 -fsSL https://claude.ai/install.sh | bash
'

# ~/.local/bin is only on PATH in login shells, and VS Code terminals are not
REMOTE_HOME=$(getent passwd "$_REMOTE_USER" | cut -d: -f6)
ln -sf "$REMOTE_HOME/.local/bin/claude" /usr/local/bin/claude
