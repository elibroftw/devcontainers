#!/usr/bin/env bash
set -e


su - "$_REMOTE_USER" -c '
    # nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh | bash
    . "$HOME/.bashrc"
    nvm install --lts
    nvm use --lts
    corepack enable
    # bun
    curl -fsSL https://bun.sh/install | bash
    # typescript
    npm install -g typescript
    npm install -g ts-node
'
