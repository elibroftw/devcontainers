#!/usr/bin/env bash
set -e

su - "$_REMOTE_USER" -c '
    cargo install sqlx-cli
'
