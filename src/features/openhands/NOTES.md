This feature installs the [OpenHands](https://docs.openhands.dev) CLI — the terminal agent, not the web product — with `uv tool install`, and adds an `oh` wrapper that feeds it the provider key already in your environment.

- The PyPI package is **`openhands`**. It is *not* `openhands-ai`: that is the separate self-hosted server product, its wheel ships no console script at all, and so the `uvx --from openhands-ai openhands` you will find in older write-ups cannot work
- `Requires-Python` is `==3.12.*` — an exact pin, not a floor — so the install asks for 3.12 explicitly. On 3.13 the resolve fails outright
- Installed system-wide (`UV_TOOL_DIR=/usr/local/share/uv/tools`, `UV_TOOL_BIN_DIR=/usr/local/bin`) rather than into root's `~/.local`, the same way `ai-agent-tools` installs its tools. It reuses the image's managed CPython instead of downloading a second copy
- Two executables land on PATH: `openhands` and `openhands-acp`. About 470 MB of tool venv, 200-odd packages; no torch, no chromium
- `tmux` comes from `dnf`, because the agent's terminal tool auto-detects it and otherwise falls back to a subprocess shell that loses its working directory between commands

## No docker socket needed

The CLI runs the agent **in-process** against a local workspace, which is why it belongs in a template that deliberately refuses to mount the docker socket. Nothing in the CLI path touches a daemon.

The exception is `openhands serve`, the containerised GUI. It shells out to `docker run … -v /var/run/docker.sock:/var/run/docker.sock … openhands:1.16.0`, so here it prints

```text
❌ Docker is not installed or not in PATH.
```

and exits cleanly. Do not mount the socket to "fix" it — that hands the agent root on the host, which is the one thing this sandbox is built to prevent. Use the terminal UI, `--headless`, `acp`, or `web` instead.

The flip side of in-process execution is that there is **no sandbox between the agent and the container**: it can reach everything `vscode` can, and `vscode` has passwordless sudo. The container is the boundary, not the agent runtime. A sudoers drop-in or a second non-sudo user is the lever if you want to narrow that.

## The web UI

```bash
oh web                 # http://0.0.0.0:12000
oh web --port 8080
```

Forward 12000 in your `devcontainer.json` — a feature cannot declare `forwardPorts`. Note it is **12000**, not the 3000 that `serve` advertises, and unlike `dsh` it already binds all interfaces.

`openhands web` serves the TUI by spawning `uv run openhands` as a child process. Run from a directory containing a `pyproject.toml`, that `uv run` syncs *your project* first — writing `.venv/` and `uv.lock` into the repo, and failing outright if the project does not resolve. The `oh` wrapper handles this: for `web` it pins `OPENHANDS_WORK_DIR` to the directory you were in and then launches from `$HOME`, where uv finds no manifest. Reach for `openhands web` directly and that protection is gone.

## Keys

OpenHands reads **three** variables and nothing else, and it ignores even those unless `--override-with-envs` is passed:

| Variable | Meaning |
| --- | --- |
| `LLM_API_KEY` | the provider key |
| `LLM_MODEL` | litellm model id, e.g. `anthropic/claude-sonnet-4-5-20250929` |
| `LLM_BASE_URL` | endpoint override; defaults to the All-Hands LLM proxy |

That is the entire surface, and it is why `oh` exists. `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY` and the rest — which this repo's templates already pass through, and which every other agent here reads directly — mean nothing to OpenHands. `oh` looks at the `LLM_MODEL` prefix, picks the matching key out of the environment, and always passes `--override-with-envs`:

| `LLM_MODEL` starts with | key it uses |
| --- | --- |
| `anthropic/` | `ANTHROPIC_API_KEY` |
| `openrouter/` | `OPENROUTER_API_KEY` |
| `openai/` | `OPENAI_API_KEY` |
| `gemini/` | `GEMINI_API_KEY` |
| `deepseek/` | `DEEPSEEK_API_KEY` |
| `xai/` | `XAI_API_KEY` |
| `groq/` | `GROQ_API_KEY` |
| `mistral/` | `MISTRAL_API_KEY` |

Set the `model` feature option to give `LLM_MODEL` a default, or export it yourself:

```bash
LLM_MODEL=anthropic/claude-sonnet-4-5-20250929 oh -t "run the tests and fix what fails"
```

`--override-with-envs` sits on the main parser, so the wrapper's prefix form is legal in front of every subcommand — `oh mcp list` works. Running plain `openhands` with no settings on disk opens an interactive setup wizard instead, which is fine at a terminal and a hang in a script.

## State

Everything it remembers lives in `~/.openhands`: `agent_settings.json`, `cli_config.json`, `mcp.json`, `hooks.json`, `conversations/`, `projects/`, `profiles/`, `cache/skills/`. Mount a named volume there to survive a rebuild:

```jsonc
"mounts": [
  "source=ai-agent-openhands,target=/home/vscode/.openhands,type=volume"
]
```

There is no relocating it — `profiles/` and `cache/` are hardcoded to `Path.home()` in the SDK, so `OPENHANDS_PERSISTENCE_DIR` moves some of it and silently leaves the rest behind. The feature creates the directory `0700` and user-owned, so a fresh named volume inherits that.

Mind that the volume holds a **plaintext API key** if anyone finishes the settings wizard or runs `openhands login`. The `oh` path never writes one to disk.

`openhands` is also a valid target for the [`skills`](../skills) feature — `skills add … -a openhands` writes to `~/.openhands/skills/<name>`, and the SDK searches `~/.agents/skills`, `~/.openhands/skills` and the legacy `~/.openhands/microagents` at startup. Since that is the same directory as the state volume, skills installed at build time need the refresh the `skills` feature already runs from `postCreateCommand` — a surviving volume would otherwise shadow the image copy.

`OPENHANDS_SUPPRESS_BANNER=1` is set as `containerEnv`, since the SDK otherwise prints a nine-line banner on every invocation, `--version` included.

## Upstream is winding down

Worth knowing before you build on it: the CLI repository was marked *no longer actively maintained* in August 2026, and `1.16.0` is the last release. That is why the `version` option pins rather than floats — nothing is coming, so a pin costs nothing and a surprise release cannot break the image. `latest` is still available if upstream resumes.

Pinning `openhands` alone is not full reproducibility, though: `openhands-workspace` depends on `openhands-agent-server` unpinned, which depends on `openhands-sdk` unpinned. Nothing in the CLI imports the agent server, so the drift is latent, but add `--with 'openhands-agent-server==<version>'` to the install if you need the resolve to be stable.
