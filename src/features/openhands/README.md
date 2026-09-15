
# OpenHands (openhands)

Installs the OpenHands CLI (the PyPI `openhands` package) with uv tool, plus tmux for its terminal backend and an `oh` wrapper that hands it the provider key already in the environment. The agent runs in-process against a local workspace, so no docker socket is needed; `openhands serve` is the one mode that wants Docker and exits without it

## Example Usage

```json
"features": {
    "ghcr.io/elibroftw/devcontainers/features/openhands:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | PyPI version of `openhands` to install. Upstream marked the CLI repository no longer actively maintained in August 2026 and 1.16.0 is the last release, so pinning costs nothing here. `latest` floats instead. | string | 1.16.0 |
| model | Default litellm model id for the `oh` wrapper, used when LLM_MODEL is unset. The wrapper reads the matching provider key out of the environment (anthropic/* takes ANTHROPIC_API_KEY, openrouter/* takes OPENROUTER_API_KEY, and so on). Blank leaves `oh` behaving like plain `openhands` until you export LLM_MODEL yourself. | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/elibroftw/devcontainers/blob/main/src/features/openhands/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
