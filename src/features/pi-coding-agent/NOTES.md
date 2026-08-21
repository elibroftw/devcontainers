This feature installs the [pi](https://pi.dev) coding agent (`@earendil-works/pi-coding-agent`) with `npm install -g --ignore-scripts`, matching pi's own install instructions.

- Requires nodejs (>= 22.19) preinstalled. The `frontend` feature's nvm-managed LTS node satisfies this, so pi declares `installsAfter: ["frontend"]`
- npm -g installs into the nvm prefix inside `$HOME`, so the install runs as `$_REMOTE_USER`, not root
- pi's bin script has a `#!/usr/bin/env node` shebang, and nvm's node is only on PATH in shells that source `~/.bashrc`. `/usr/local/bin/pi` is therefore a wrapper that loads nvm and execs the real binary, rather than the symlink the claude-code feature uses

pi reads provider API keys straight from the environment, so pass them through with `remoteEnv` in your `devcontainer.json`:

| Variable | Provider |
| --- | --- |
| `ANTHROPIC_API_KEY` | Anthropic |
| `OPENAI_API_KEY` | OpenAI |
| `OPENROUTER_API_KEY` | OpenRouter |
| `GEMINI_API_KEY` | Google Gemini |
| `DEEPSEEK_API_KEY` | DeepSeek |
| `XAI_API_KEY` | xAI |
| `GROQ_API_KEY` | Groq |
| `MISTRAL_API_KEY` | Mistral |

See pi's [providers documentation](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/providers.md) for the full list. `/login` inside pi stores keys in `~/.pi/agent/auth.json` instead.

Config, credentials, and session history live in `~/.pi/agent`, so mount a named volume at `~/.pi` to survive rebuilds.
