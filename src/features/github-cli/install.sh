#!/usr/bin/env bash
set -e

# Drop the repo file in directly rather than using `dnf config-manager --add-repo`,
# whose syntax changed between dnf4 (AlmaLinux 9) and dnf5 (AlmaLinux 10)
curl --proto '=https' --tlsv1.2 -sSL https://cli.github.com/packages/rpm/gh-cli.repo -o /etc/yum.repos.d/gh-cli.repo

dnf install -y gh
