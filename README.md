# Elijah's Dev Container Templates

- Common Includes
  - Fedora base
  - `bash` (for "Unix" shell scripting)
  - `python` (latest 3.X for scripting purposes)
  - `nix` (with flakes enabled)
  - `just` (command runner)
  - infisical (secret management)
  - `yq` and `jq`

Possible Features (R&D required)

- Frontend Development
  - `nvm` (with LTS pre-installed)
    - `typescript` and `ts-node` installed globally by default
    - `pnpm` enabled by default (via `corepack enable`)
  - `bun`
    - Not as adopted, but I'm including it to do my part
- Rust (backend perspective)
  - `rustc` and `cargo`
  - `sqlx`

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
