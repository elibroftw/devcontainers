#!/usr/bin/env bash
set -e

curl https://sh.rustup.rs -sSf | sh -s -- -y
. "$HOME/.cargo/env"
rustup component add rustfmt
# https://dystroy.org/bacon/
cargo install --locked bacon --features "clipboard sound"
