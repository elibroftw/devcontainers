#!/usr/bin/env bash
set -e

# VERSION and MODEL are the `version` and `model` options, passed in uppercased
# by the devcontainer CLI
OPENHANDS_VERSION="${VERSION:-1.16.0}"
DEFAULT_MODEL="${MODEL:-}"

USER_HOME=$(getent passwd "$_REMOTE_USER" | cut -d: -f6)

# The agent's terminal tool auto-detects tmux, and without it falls back to a
# subprocess shell that loses its working directory between commands, with a
# warning rather than an error. tmux is in AlmaLinux BaseOS.
dnf install -y tmux

# The python feature ships uv, but install it in case this feature is used alone
if ! command -v uv > /dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh
fi

# Feature scripts run as root, so put the tool somewhere shared instead of
# root's ~/.local where the remote user cannot reach it
export UV_TOOL_DIR=/usr/local/share/uv/tools
export UV_TOOL_BIN_DIR=/usr/local/bin
# and reuse an interpreter the image already has, rather than downloading a
# second one into root's home that the tool venv would then point at forever
export UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python
export UV_PYTHON_BIN_DIR=/usr/local/bin

# `openhands` is the CLI. It is NOT `openhands-ai`, which is the separate
# self-hosted server product and ships no console script at all -- the
# `uvx --from openhands-ai openhands` in older write-ups cannot work.
# Requires-Python is `==3.12.*`, an exact pin rather than a floor, so asking for
# 3.12 is mandatory: on 3.13 the resolve fails outright.
if [ "$OPENHANDS_VERSION" = "latest" ]; then
    uv tool install --python 3.12 openhands
else
    uv tool install --python 3.12 "openhands==${OPENHANDS_VERSION}"
fi

# uv creates these root-owned, so let every user read and execute them
chmod -R a+rX "$UV_TOOL_DIR" "$UV_PYTHON_INSTALL_DIR"

# Everything openhands remembers lives in one directory, and the SDK hardcodes
# parts of it to Path.home(), so no env var can move it -- mount a volume here
# or lose your conversations on rebuild. Created owned by the user, because
# docker seeds a fresh named volume from the image path, ownership included.
install -d -m 0700 -o "$_REMOTE_USER" -g "$_REMOTE_USER" "$USER_HOME/.openhands"

# `oh` is the same wrapper convention pi and dsh use, and it does two things.
#
# One: openhands reads only LLM_API_KEY / LLM_MODEL / LLM_BASE_URL -- it ignores
# the ANTHROPIC_API_KEY and friends that this image already passes through --
# and it ignores even those unless --override-with-envs is passed, which lives
# on the main parser and so is legal in front of any subcommand.
#
# Two: `openhands web` serves the TUI over http by spawning `uv run openhands`
# (tui/serve.py). Run from a directory that has a pyproject.toml, `uv run` syncs
# THAT project first, writing .venv/ and uv.lock into the repo, and fails
# outright if the project does not resolve. So pin the agent's working directory
# with OPENHANDS_WORK_DIR -- which locations.py honours -- and launch from $HOME
# where uv finds no manifest.
printf '%s\n' '#!/usr/bin/env bash' "default_model=\"${DEFAULT_MODEL}\"" > /usr/local/bin/oh
cat >> /usr/local/bin/oh <<'WRAPPER'
if [ -z "${LLM_MODEL:-}" ] && [ -n "$default_model" ]; then
    export LLM_MODEL="$default_model"
fi
if [ -z "${LLM_API_KEY:-}" ]; then
    case "${LLM_MODEL:-}" in
        anthropic/*)  export LLM_API_KEY="${ANTHROPIC_API_KEY:-}" ;;
        openrouter/*) export LLM_API_KEY="${OPENROUTER_API_KEY:-}" ;;
        openai/*)     export LLM_API_KEY="${OPENAI_API_KEY:-}" ;;
        gemini/*)     export LLM_API_KEY="${GEMINI_API_KEY:-}" ;;
        deepseek/*)   export LLM_API_KEY="${DEEPSEEK_API_KEY:-}" ;;
        xai/*)        export LLM_API_KEY="${XAI_API_KEY:-}" ;;
        groq/*)       export LLM_API_KEY="${GROQ_API_KEY:-}" ;;
        mistral/*)    export LLM_API_KEY="${MISTRAL_API_KEY:-}" ;;
    esac
fi
if [ "${1:-}" = "web" ]; then
    export OPENHANDS_WORK_DIR="${OPENHANDS_WORK_DIR:-$PWD}"
    cd "$HOME" || exit 1
fi
exec openhands --override-with-envs "$@"
WRAPPER
chmod +x /usr/local/bin/oh

# Smoke test as the remote user, the way vscode will hit it. --version exits
# before any store is read, so this needs no network and leaves no state behind.
su - "$_REMOTE_USER" -c 'openhands --version'
