#!/usr/bin/env bash
set -e

# nvm
echo "installing nvm" > /etc/frontend-log
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh | bash
. "$HOME/.bashrc"
nvm install --lts
nvm use --lts
corepack enable
echo "installing bun" > /etc/frontend-log
# bun
curl -fsSL https://bun.sh/install | bash
echo "installing typescript" > /etc/frontend-log
# typescript
npm install -g typescript
npm install -g ts-node
