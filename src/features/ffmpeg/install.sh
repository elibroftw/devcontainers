#!/usr/bin/env bash
set -e

# RPM Fusion carries the full ffmpeg build; EPEL only ships ffmpeg-free,
# which is stripped of the codecs most projects actually need.
# RPM Fusion requires EPEL, and %rhel resolves to 9 or 10 depending on the base image.
dnf install -y epel-release
dnf install -y "https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm"

# --allowerasing swaps out ffmpeg-free if something already pulled it in
dnf install -y --allowerasing ffmpeg
