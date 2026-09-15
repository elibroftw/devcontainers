### zoxide.sh (installed to /etc/profile.d/zoxide.sh)

# `z` and `zi` are shell functions that `zoxide init` writes, so the binary on
# its own does nothing. On RHEL family distros /etc/profile.d is sourced by both
# /etc/profile (login shells) and /etc/bashrc (interactive shells), for every
# user, which a line in one ~/.bashrc would not cover.
#
# The BASH_VERSION guard is because /etc/profile is POSIX sh and the init script
# is not. The command -v guard is for `su -`, which drops the image's PATH and
# so cannot see the nix profile.
if [ -n "${BASH_VERSION-}" ] && command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi
