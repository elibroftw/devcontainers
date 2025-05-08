#!/usr/bin/env bash
set -e

su - "$_REMOTE_USER" -c '
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    . "$HOME/.cargo/env"
    rustup component add rustfmt
    # https://dystroy.org/bacon/
    cargo install --locked bacon --features "clipboard sound"
'
