#!/usr/bin/env bash
set -e

# dsh needs nodejs (^22.19 || >= 24) preinstalled, which the frontend feature
# provides via nvm. Fail with a clear error rather than an obscure
# npx-not-found from the install below.
if ! su - "$_REMOTE_USER" -c '. "$HOME/.bashrc" && command -v node' > /dev/null; then
    echo "deepseek-harness requires nodejs: install the frontend feature (or another nodejs source) before deepseek-harness" >&2
    exit 1
fi

# Upstream ships no installer: `npx @deepseek-ai/dsh web` is the documented way
# to run the harness, so "installing" it means priming the npx cache with the
# package and its ~450 transitive dependencies, which is the several-minute wait
# an unprimed first launch would otherwise pay. -y answers the "Ok to proceed?"
# prompt npx asks on a cache miss, and --version makes it print and exit instead
# of booting the web server. npx keeps that cache in $HOME/.npm/_npx, so this
# runs as $_REMOTE_USER; a later `npx @deepseek-ai/dsh web` resolves from it
# without touching the network.
su - "$_REMOTE_USER" -c '
    . "$HOME/.bashrc"
    npx -y @deepseek-ai/dsh --version
'

# The dsh bin is inside the npx cache under a content hash, not on PATH, and
# nvm's node is only on PATH in shells that source ~/.bashrc. Wrap both: load
# nvm, then let npx resolve the cached package. -y keeps the wrapper
# non-interactive if the cache ever misses (a fresh $HOME, or root).
cat > /usr/local/bin/dsh <<'WRAPPER'
#!/usr/bin/env bash
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
exec npx -y @deepseek-ai/dsh "$@"
WRAPPER
chmod +x /usr/local/bin/dsh
