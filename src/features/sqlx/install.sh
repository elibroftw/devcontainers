#!/usr/bin/env bash
set -e

su - "$_REMOTE_USER"

cargo install sqlx-cli
