#!/usr/bin/env bash
set -e

# pi is an npm package that needs nodejs (>= 22.19) preinstalled, which the
# frontend feature provides via nvm. Fail with a clear error rather than an
# obscure npm-not-found from the install below.
if ! su - "$_REMOTE_USER" -c '. "$HOME/.bashrc" && command -v node' > /dev/null; then
    echo "pi requires nodejs: install the frontend feature (or another nodejs source) before pi" >&2
    exit 1
fi

# npm -g installs into the nvm prefix inside $HOME, so run as the remote user
# rather than root. --ignore-scripts follows pi's own install instructions.
su - "$_REMOTE_USER" -c '
    . "$HOME/.bashrc"
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent
'

# pi's bin script has a `#!/usr/bin/env node` shebang, and nvm's node is only
# on PATH in shells that source ~/.bashrc, so a plain symlink into
# /usr/local/bin (the claude-code trick) breaks in non-interactive shells.
# Wrap instead: load nvm, then hand off to the real binary.
cat > /usr/local/bin/pi <<'WRAPPER'
#!/usr/bin/env bash
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
PI_BIN="$(npm prefix -g)/bin/pi"
if [ ! -x "$PI_BIN" ]; then
    # the default node version changed since pi was installed; use any copy left under nvm
    for PI_BIN in "$NVM_DIR"/versions/node/*/bin/pi; do
        [ -x "$PI_BIN" ] && break
    done
fi
exec "$PI_BIN" "$@"
WRAPPER
chmod +x /usr/local/bin/pi
