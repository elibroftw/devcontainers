
# Python (python)

Installs uv, and optionally a Python version managed by it

## Example Usage

```json
"features": {
    "ghcr.io/elibroftw/devcontainers/features/python:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Python version for uv to install. Leave blank to install uv only. Anything `uv python install` accepts works, including free-threaded builds (3.14t) and PyPy (pypy@3.11). | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/elibroftw/devcontainers/blob/main/src/features/python/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
