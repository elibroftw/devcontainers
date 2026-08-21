#!/usr/bin/env bash
set -e

# SKILLS is the `skills` option, passed uppercased by the devcontainer CLI
SKILL_SOURCES="${SKILLS:-vercel-labs/skills@find-skills}"
# AGENTS is the `agents` option
TARGET_AGENTS="${AGENTS:-pi}"

# The skills CLI is `npx skills`, so nodejs must be preinstalled. The frontend
# feature provides it via nvm. Fail with a clear error rather than letting the
# installer below drown in npx-not-found noise.
if ! su - "$_REMOTE_USER" -c '. "$HOME/.bashrc" && command -v node' > /dev/null; then
    echo "skills requires nodejs: install the frontend feature (or another nodejs source) before skills" >&2
    exit 1
fi

AGENT_FLAGS=""
for agent in $TARGET_AGENTS; do
    AGENT_FLAGS="$AGENT_FLAGS -a $agent"
done

# A script the remote user can rerun, baked with the resolved option values.
# It runs once here at build time, and again from the feature's
# postCreateCommand: agents keep skills in $HOME (~/.pi/agent/skills,
# ~/.claude/skills), and templates like ai-agent mount those paths as named
# volumes, which shadow the image copy after their first creation. Re-running
# post-create refreshes skills that a surviving volume would otherwise freeze.
# -g installs to the user-level skill directories, --copy writes real files
# rather than symlinks back to ~/.agents so a volume holds a working copy
# instead of dangling links after a rebuild, and -y keeps it non-interactive.
cat > /usr/local/bin/install-agent-skills <<INSTALLER
#!/usr/bin/env bash
set -e
. "\$HOME/.bashrc"
for source in $SKILL_SOURCES; do
    npx -y skills add "\$source" -g --copy -y $AGENT_FLAGS
done
INSTALLER
chmod +x /usr/local/bin/install-agent-skills

su - "$_REMOTE_USER" -c /usr/local/bin/install-agent-skills
