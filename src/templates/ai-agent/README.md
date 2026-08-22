
# AlmaLinux AI Agent Sandbox (ai-agent)

A sandbox for running coding agents, with the tools an agent calls (git, gh, rg, yq, just, OCR and PDF extraction) and the runtimes it writes against (uv, node)

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|


## Calling APIs on the host from inside the container

[chandra](https://github.com/datalab-to/chandra) and
[surya](https://github.com/datalab-to/surya) are installed in the container, but only
as clients. Both run their inference against a vLLM (or llama.cpp) server speaking an
OpenAI-compatible API, and that server belongs on the host where the GPU and the
multi-GB weights already live. The container just needs a URL.

Three things have to line up. Miss any one and you get a connection refused that
looks identical in all three cases.

### 1. The host service must listen on more than loopback

A server bound to `127.0.0.1` is unreachable from a container, because the container
is on the other side of a bridge interface. Bind `0.0.0.0` instead:

```bash
# chandra: launches its own vLLM container, published on 8000
chandra_vllm

# surya: give it its own port, one vLLM process serves one model
surya_ocr DATA_PATH --keep_server        # spawns and leaves a server up
```

Check what it actually bound to before blaming the container:

```bash
ss -tlnp | grep -E '8000|8001'   # want 0.0.0.0:8000, not 127.0.0.1:8000
```

### 2. The container needs a name for the host

Docker Desktop resolves `host.docker.internal` out of the box. **On Linux it does
not exist** unless you ask for it, which is what the `runArgs` line in
`devcontainer.json` does:

```jsonc
"runArgs": ["--add-host=host.docker.internal:host-gateway"]
```

Podman provides `host.containers.internal` natively and ignores the flag, so on
Podman use that name instead. `--network=host` also works on Linux and makes
`localhost` mean the host, but it throws away network isolation and breaks
`forwardPorts`, so prefer the host-gateway route.

### 3. The host firewall must allow the bridge

This is the step that catches people on Fedora and RHEL derivatives, where firewalld
drops traffic from the docker bridge by default. The container resolves the name, the
route exists, and the connection still hangs:

```bash
# trust the bridge interface (docker0, or podman0 / cni-podman0 for Podman)
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload
```

### Wiring it up

`devcontainer.json` already sets these. Adjust the ports to match your host. The
variable names come from each project's own configuration:

| Variable | Belongs to | Purpose |
| --- | --- | --- |
| `VLLM_API_BASE` | chandra | Server URL, defaults to `http://localhost:8000/v1` |
| `VLLM_MODEL_NAME` | chandra | Model served, defaults to `chandra` |
| `SURYA_INFERENCE_BACKEND` | surya | Set to `vllm` to stop it auto-spawning its own |
| `SURYA_INFERENCE_URL` | surya | Attach to an already-running OpenAI-compatible server |

Swapping `localhost` for `host.docker.internal` is the whole change:

```jsonc
"remoteEnv": {
    "VLLM_API_BASE": "http://host.docker.internal:8000/v1",
    "VLLM_MODEL_NAME": "chandra",
    "SURYA_INFERENCE_BACKEND": "vllm",
    "SURYA_INFERENCE_URL": "http://host.docker.internal:8001/v1"
}
```

Verify from inside the container before debugging anything else:

```bash
curl -s http://host.docker.internal:8000/v1/models | yq -p json
```

### The same pattern works for anything else on the host

Ollama (`OLLAMA_HOST=http://host.docker.internal:11434`), a database, a staging API
— it is always the same three steps: bind beyond loopback, give the container a name
for the host, open the firewall to the bridge.

## The DeepSeek Harness web UI

`dsh web` serves the harness's browser UI on `127.0.0.1:3080`, which this template forwards.
Two flags matter inside a container:

```bash
# nothing in here can open a browser, and dsh tries to on a local launch
dsh web --no-open

# only needed to reach it from outside VS Code's forwarder (LAN, plain docker -p);
# the /api trust fence has to be told the authority the browser will actually show
dsh web --host 0.0.0.0 --trusted-host <authority>
```

Give it a model under **Settings → Models**, or export `DEEPSEEK_API_KEY` on the host —
`remoteEnv` already passes that one through, and the shipped DeepSeek route reads it per
request. Settings, credentials, and session history land in `~/.dsh`, a named volume, so
they survive a rebuild. `dsh --profile headless "run the tests"` answers one task and exits,
which is the mode to script against.

## Why there is no docker socket mount

Mounting `/var/run/docker.sock` is the usual way to let a container start containers,
and it hands whatever is inside root on the host — the agent could start a privileged
container mounting `/`. That defeats the point of running the agent in a sandbox at
all. If an agent genuinely needs to build images, give it a rootless Podman socket or
a throwaway VM instead.


---

_Note: This file was auto-generated from the [devcontainer-template.json](https://github.com/elibroftw/devcontainers/blob/main/src/templates/ai-agent/devcontainer-template.json).  Add additional notes to a `NOTES.md`._
