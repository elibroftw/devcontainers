# Elijah's Dev Containers

Contains an AlamLinux base image, frontend features, and templates. [Rationale](#rationale)

Example uses (`.devcontainer\devcontainer.json`)

```json
{
  "image": "ghcr.io/elibroftw/devcontainers/templates/aspnet-full-stack"
}
```

```json
{
  "name": "Python Malware Analysis Container",
  "image": "ghcr.io/elibroftw/devcontainers/images/base-almalinux",
  "features": {
    "ghcr.io/elibroftw/devcontainers/features/python": { "version": "3.11" },
  },
}
```

It's recommended you auto-install dependencies [on container start](https://code.visualstudio.com/remote/advancedcontainers/start-processes) by using the `"postAttachCommand"` field.

AlamLinux Base Image Dev Container: `ghcr.io/elibroftw/devcontainers/images/base-almalinux`

- AlmaLinux base (RHEL API guarantee, Fedora is the upstream)
- `git`
- Shells
  - `bash` as the default shell
  - Nix (with flakes enabled)
  - `powershell`
- `python3` (latest 3.X for scripting purposes)
- `just` (command runner)
- `yq` (like jq, but supports yaml and toml files)
- ansible (for deployment)
- eza (ls successor)
- ripgrep (grep successor)
- infisical (secret management)

AI/ML Base Image Dev Container: `ghcr.io/elibroftw/devcontainers/images/base-ai-almalinux`

Everything above, plus a torch stack preinstalled in a shared venv at `/opt/ai`, first on `PATH`.
[Details](src/images/base-ai-almalinux/README.md)

- `torch` and `torchvision` (CPU wheels; [rebuild with `TORCH_INDEX=cu130`](src/images/base-ai-almalinux/README.md#gpu-builds) for CUDA)
- `transformers` and `accelerate`
- `librosa` for audio, with libsndfile vendored in its `soundfile` wheel
- `huggingface_hub`, with the `hf` CLI and Xet transfers
- `HF_TOKEN` passed through from your host environment at attach time, never baked into a layer
- the host's `~/.cache/huggingface` bind mounted in, so weights are downloaded once and every
  container that mounts it shares the one copy
- `uv pip install <pkg>` lands in the shared venv without sudo or an activate

## Features

Add these to the `"features"` field of your `devcontainer.json`, namespaced under `ghcr.io/elibroftw/devcontainers/features/`.

| Feature | Installs |
| --- | --- |
| `ai-agent-tools` | Document extraction and OCR: poppler-utils, tesseract, ImageMagick, unpaper, zbar, ocrmypdf, docling; plus runpodctl for RunPod GPU pods |
| `claude-code` | The Claude Code CLI and its VS Code extension |
| `csharp` | .NET SDK (channel configurable, defaults to LTS) and the C# Dev Kit extension |
| `deepseek-harness` | DeepSeek Harness (`dsh`), DeepSeek's coding agent, web UI on port 3080 (needs the `frontend` feature's node) |
| `ffmpeg` | FFmpeg from RPM Fusion, rather than EPEL's codec-stripped `ffmpeg-free` |
| `frontend` | nvm, node LTS, corepack (yarn, pnpm), typescript, ts-node |
| `github-cli` | `gh` |
| `pi-coding-agent` | The pi coding agent CLI from npm (needs the `frontend` feature's node) |
| `postgresql-client` | `psql` |
| `python` | `uv`, and optionally a Python version for it to manage |
| `rust` | rustup, cargo, rustfmt, [bacon](https://dystroy.org/bacon/) |
| `skills` | Agent skills from [skills.sh](https://skills.sh) via `npx skills add`, find-skills by default (needs the `frontend` feature's node) |
| `sqlx` | `sqlx-cli` (installs after `rust`) |

## Templates

`ghcr.io/elibroftw/devcontainers/<template>`

- `/templates/rust-full-stack`
  - Rust, Axum, sqlx, nvm, typescript, ts-node, yarn, pnpm, psql
  - Also useful for backend-only or frontend-only projects
- `/templates/aspnet-full-stack`
  - dotnet, nvm, typescript, ts-node, pnpm, psql, pi, and the C# skills find-skills, dotnet-best-practices, csharp-developer
  - can be used for backend-only and frontend-only projects
- `/templates/ai-agent`
  - Claude Code, pi, DeepSeek Harness (`dsh web` on port 3080), gh, uv, nvm, OCR and PDF extraction, plus the base image's git, ripgrep, yq, and just
  - A sandbox for letting a coding agent run against a repo. Deliberately has no
    docker socket mount — that would hand the agent root on the host.

Preinstalling more skills on the ai-agent template is one feature option — here, RunPod's whole official set (GPU pod management, flash file transfer, usage, MCP) alongside the default find-skills:

```json
{
    "image": "ghcr.io/elibroftw/devcontainers/templates/ai-agent",
    "features": {
        "ghcr.io/elibroftw/devcontainers/features/skills": {
            "skills": "vercel-labs/skills@find-skills runpod/runpod-plugins-official",
            "agents": "pi claude-code"
        }
    }
}
```

Browse [skills.sh](https://skills.sh) for sources; `owner/repo` installs every skill in the repository, `owner/repo@skill` installs just that one.

Both templates expect `PostgreSQL` itself to run in another docker container. [Tutorial](https://www.docker.com/blog/how-to-use-the-postgres-docker-official-image/#Using-Docker-Compose)

Linux _could_ be the future of desktop operating systems, however it doesn't help when influencers and the community do everything they can do hamstring its adoption by promoting distros like Ubuntu, Linux Mint, Arch and desktop-environments like GNOME to people coming from stable operating systems like Windows and macOS with a non-trivial setup (e.g. 1440p displays). If you want to know why I'm like this, feel free to read [Linux Desktop Sucks!](https://blog.elijahlopez.ca/posts/linux-desktop-sucks/).

## Replacing the Base Image

If you want to replace the base image with something else, I recommend the following

1. Ensure `/bin` is in in the `PATH` environment variable. If not:

    ```Dockerfile
    ENV PATH="$PATH:/bin"
    ```

2. Ensure the default shell is `bash`. If not:

    ```Dockerfile
    SHELL ["/bin/bash", "-c"]
    ```

## Curl argument explanation

- `--proto '=https'`: only use the https protocol, ensuring that a redirect to HTTP does not work
- `-L`: follow redirects, aka `--location`
- `s`: silent
- `-S`: when silent, show error messages if failed
- `-f`: fail if HTTP response code is 400+
- `--tlsv1.2`: use minimum TLS v1.2

## Resources

- [Advanced container configuration](https://code.visualstudio.com/remote/advancedcontainers/overview)
- https://docs.docker.com/build/building/multi-platform/#strategies
- https://containers.dev/implementors/features-distribution/
- https://github.com/home-assistant/devcontainer/blob/c1479dcf6b8b55e2cdfaba53515fe547d5acd08a/.github/workflows/builder.yaml#L50
- https://docs.docker.com/reference/cli/docker/manifest/#inspect-an-images-manifest-object
- https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/rust/tags
- [targeted named volume](https://code.visualstudio.com/remote/advancedcontainers/improve-performance#_use-a-targeted-named-volume)

## Rationale

Microsoft's VSCode team does a poor job at explaining the big picture, so I will explain my conceptual understanding of features and templates.

Why does this repo exist? I will never voluntarily daily drive Ubuntu (because of snaps) or Debian (outdated packages, poor installation instructions), so why would I want to daily drive a non-Debian distro, develop inside a debian distro, and then deploy to another debian distro? All while knowing that there are server distros like AlmaLinux, Rocky Linux (RHEL), and CentOS Stream? Not to mention that the "useful" default VSCode dev containers don't even support bash by default. I came to the conclusion that I should get a jump start on my Linux desktop journey by creating a dev container that encapsulates my philosophy. An alternative I considered is NixOS, but I have not been convinced to try to use it as there is no guarantee it will work with my workflow.

Another reason why this repo is important is for people who want to do the same thing as me but for their own workflow, I'm not going to shove my KDE Fedora opinion down your throat. Just as how the Potions textbook in _Harry Potter and the Half Blood Prince_ has helpful notes, this repo is the same but for VSCode Dev Containers.

If you follow Microsoft's own tutorials, it will lead you to improperly create a dev container.

1. If you use their base images, you inherit the no `/bin` on PATH problem.
2. They don't teach you how to properly build your Dockerfile so that it works on ARM (aarch64).
3. They don't teach you how to use non-Microsoft hosted distros (i.e. non-debian, non-ubuntu, non-alpine) like I have done. They actually try to [dissuade you](https://github.com/devcontainers/images/tree/main/build#the-build-namespace) from using anything other than debian and ubuntu images.

### Why not AlPiNe

Similar logic to Debian, if I'm not daily driving it, I'm not going to use it for a dev environment nor for deployment.

Also read [Why I Will Never Use Alpine Linux Ever Again (2023)](https://medium.com/better-programming/why-i-will-never-use-alpine-linux-ever-again-a324fd0cbfd6) which explains that using Node or Python's numpy has different results.

## Feature Development Advise

Feature installs scripts are run as the root user. This means that without changing the user, I was installing features accessible only by the root user.

While debugging, I realized this fact, so if you are developing your own features, switch to the expected container user before running non-sudo installation commands in your `install.sh` file.

`su - "$_REMOTE_USER"`

If for some reason this isn't enough for your use-case, or you need to maintain being the root user, you can read the [rust-Debian](https://github.com/devcontainers/features/blob/main/src/rust/install.sh) feature implementation for more ideas.


```bash
POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
    if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
        USERNAME=${CURRENT_USER}
        break
    fi
done
```

## Notes

I was wondering why I wrote `curl` starting with `curl --proto '=https' --tlsv1.2`.

- Specifying the protocol protects against protocol downgrade attacks via redirect
- Specifying the minimum TLS version protects against vulnerable encryption protocols
