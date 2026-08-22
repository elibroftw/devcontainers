This feature installs [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`), DeepSeek's plugin-architecture coding agent. Upstream ships no installer — `npx @deepseek-ai/dsh web` is the documented way to run it — so the install primes the npx cache with `npx -y @deepseek-ai/dsh --version` instead of pulling ~450 packages on someone's first launch.

- Requires nodejs (`^22.19` or `>= 24`) preinstalled. The `frontend` feature's nvm-managed LTS node satisfies this, so `deepseek-harness` declares `installsAfter: ["frontend"]`
- `-y` answers the `Ok to proceed?` prompt npx asks on a cache miss, and `--version` prints and exits rather than booting a server during the build
- npx keeps its cache in `$HOME/.npm/_npx`, so the install runs as `$_REMOTE_USER`, not root. Root gets no primed cache and would re-download on first use
- `/usr/local/bin/dsh` is a wrapper that loads nvm and forwards to `npx -y @deepseek-ai/dsh`, since the cached bin lives under a content hash rather than on PATH. A cached package satisfies the unpinned spec, so the wrapper resolves offline in well under a second — it does not check npm for a newer version on every call. `npx -y @deepseek-ai/dsh web` works exactly as upstream documents it, too

## The web UI

```bash
dsh web              # http://127.0.0.1:3080
dsh web --port 8080  # flags after the profile belong to the web app
```

Forward 3080 in your `devcontainer.json` — a feature cannot declare `forwardPorts`:

```jsonc
"forwardPorts": [3080]
```

| Flag | Why you want it in a container |
| --- | --- |
| `--no-open` | `dsh web` opens the URL in a browser on a local launch, and there is no browser inside the container. The failure is caught and logged, not fatal |
| `--host 0.0.0.0` | The default bind is `127.0.0.1`. VS Code forwards a loopback-bound port fine because its forwarder runs inside the container; reaching the server from the LAN or through a plain `docker -p` does need all interfaces |
| `--trusted-host <authority>` | The `/api` browser-trust fence only accepts authorities it knows. Add the one your browser actually shows when it is not the address `dsh` bound |

`dsh --profile headless "run the tests"` answers one task and exits, which is the mode to reach for from a script.

## Keys and state

`dsh` resolves provider keys per request from the process environment first, then `<workspace>/.env`, then `$DSH_HOME/.env`. Pass them through with `remoteEnv` in your `devcontainer.json`:

| Variable | Provider |
| --- | --- |
| `DEEPSEEK_API_KEY` | DeepSeek — the shipped chat route and `web_search` both resolve this one |
| `DEEPSEEK_BASE_URL` | DeepSeek endpoint override |
| `DSH_TELEMETRY_DISABLED` | Any non-empty value disables session telemetry |

Other providers (Anthropic, OpenAI, a custom OpenAI-compatible gateway) are configured in **Settings → Models** in the web UI, which writes `$DSH_HOME/settings.yaml` and stores the key in `$DSH_HOME/.credentials.yaml`.

Everything `dsh` remembers — profiles, settings, credentials, sessions, attachments — lives under `$DSH_HOME`, which defaults to `~/.dsh`, so mount a named volume there to survive rebuilds. The primed npx cache is in `~/.npm` and stays in the image.
