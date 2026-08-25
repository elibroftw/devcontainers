# AI/ML Base Image

`ghcr.io/elibroftw/devcontainers/images/base-ai-almalinux`

Everything in [base-almalinux](../base-almalinux), plus the libraries you reach
for before you have decided what you are building:

| Package | Why it is here |
| --- | --- |
| `torch` | the runtime everything else sits on |
| `torchvision` | image transforms, datasets, and pretrained vision models |
| `transformers` | the model definitions and pipelines |
| `accelerate` | device placement and `device_map="auto"`, which `transformers` uses internally |
| `librosa` | audio loading, resampling, and mel spectrograms / MFCCs for speech and audio models |
| `huggingface_hub` | the `hf` command; on x86_64 and aarch64 it pulls `hf_xet`, the Xet transfer backend, as a hard dependency rather than an extra |

```json
{
  "image": "ghcr.io/elibroftw/devcontainers/images/base-ai-almalinux"
}
```

`librosa` brings `soundfile` with it, which vendors libsndfile inside its own
wheel, so wav, flac, ogg and mp3 all load with no `dnf` package involved. Formats
beyond that go through ffmpeg, which is a [separate
feature](../../features/ffmpeg) in this repo rather than part of the image.

## The venv

The stack lives in one virtualenv at `/opt/ai`, owned by `vscode` and first on
`PATH`, rather than in the distro python that `dnf` owns. `python`, `pip` and
`hf` all resolve there without activating anything. It is built as `vscode`
rather than chowned afterwards, because a `chown -R` over a finished torch install
copies every file into a second layer and roughly doubles the published image.

`VIRTUAL_ENV` is baked in and points at it, which is what `uv` reads, so adding a
package is:

```bash
uv pip install datasets peft
```

No `sudo`, no activation.

That same baked `VIRTUAL_ENV` has one consequence worth knowing: **`uv pip
install` always targets `/opt/ai`, even inside a project that has its own
`.venv`.** The project-scoped commands do the expected thing — `uv sync`,
`uv run` and `uv add` all use the workspace's `.venv` and ignore `VIRTUAL_ENV`
with a warning — so reach for `uv add <pkg>` when the package belongs to the
project, and `uv pip install` when you want it in the shared image-wide venv.
`VIRTUAL_ENV= uv pip install <pkg>` also works if you want the project venv
without a manifest entry.

One caveat, and only on a Linux host whose own uid is not 1000: the CLI's
`updateRemoteUserUID` remaps `vscode` to your uid but chowns nothing outside
`/home/vscode`, so `/opt/ai` stays owned by the old id. Either take it once with
`sudo chown -R $(id -u): /opt/ai` or just `sudo uv pip install`. Docker Desktop
on Windows and macOS does no remapping, so this does not come up there.

## `HF_TOKEN`

Export `HF_TOKEN` on the host and it is in the container. It is passed through
`remoteEnv` at attach time rather than baked into a layer, so it never reaches
the image or `docker inspect`. Leave it unset and `huggingface_hub` reads the
empty value as "no token", which is what you want for public weights.

Gated repos, private repos, and pushing all need it. Check it landed with:

```bash
hf auth whoami
```

The base image also ships `infisical` if you would rather pull the token at
runtime than keep it in your shell profile.

## The model cache

`~/.cache/huggingface` is bind mounted from the host, and `HF_HOME` points at it,
so:

- a 15 GB download survives a container rebuild
- every container that mounts the same path shares one copy
- your host's own python sees the same cache, because `huggingface_hub` defaults
  to `~/.cache/huggingface` on Windows and macOS as well as Linux

`TORCH_HOME` is pointed inside it too, so `torchvision`'s pretrained weights —
which are not Hub downloads and would otherwise land in an unmounted
`~/.cache/torch` — persist on the same terms. `torch.hub.get_dir()` reports
`/home/vscode/.cache/huggingface/torch/hub` inside the container, and `hf`'s own
cache commands ignore that subdirectory.

The cache commands are `hf cache ls` to see what is in there, `hf cache rm
<repo-id>` to drop a repo or a single revision, and `hf cache prune` to reclaim
detached revisions and leftover `.incomplete` downloads. Both `rm` and `prune`
take `--dry-run`, which is worth using: this is host disk, not container-local.
(The 0.x spellings `scan-cache` and `delete-cache`, and the `hf cache scan` /
`hf cache delete` you may find in older notes, do not exist in `hf` 1.x.)

### If the mount does not land

The mount source is `${localEnv:HOME}${localEnv:USERPROFILE}` — the usual
devcontainer trick for "home directory on any host", and what the base image
already uses for `.ssh` and `Downloads`. It relies on exactly one of the two
being set. That holds for the VS Code extension on Windows, but **if you run
`devcontainer up` from Git Bash or MSYS2, both are set**, they get concatenated
into a nonsense path, and Docker helpfully creates it instead of failing. The
symptom is a cache that is empty after every rebuild.

`postCreateCommand` warns when `HF_HOME` is not actually a mount point, so watch
for that line. The fix is either to run from a shell where only one is set, or to
switch to a named volume — which keeps the sharing between containers and gives
up the sharing with the host:

```json
"mounts": [
  "source=huggingface,target=/home/vscode/.cache/huggingface,type=volume"
]
```

## GPU builds

The published image carries **CPU** torch. That keeps it a few GB instead of
fifteen, and it means the image still starts on a machine without an NVIDIA card.

To get a CUDA build, point `TORCH_INDEX` at the matching wheel index and rebuild.
The `devcontainer` CLI has no `--build-arg` flag — build args come from the
config — so either edit `"build": {"args": {...}}` in
`.devcontainer/devcontainer.json`, or keep a second config and leave the
committed one alone:

```bash
# .devcontainer/devcontainer.cuda.json with "args": { "TORCH_INDEX": "cu130" }
devcontainer build --workspace-folder src/images/base-ai-almalinux \
  --config src/images/base-ai-almalinux/.devcontainer/devcontainer.cuda.json \
  --image-name base-ai-almalinux:cu130
```

Or, for a one-off, go straight to docker, which does take the flag:

```bash
docker build --build-arg TORCH_INDEX=cu130 \
  -t base-ai-almalinux:cu130 src/images/base-ai-almalinux/.devcontainer
```

Which index:

| Index | Notes |
| --- | --- |
| `cpu` | the default, and what is published |
| `cu126` | oldest cards still served (x86_64 covers GTX 750 up) |
| `cu130` | current; drops the oldest architectures |
| `cu132` | newest index |
| `cu128`, `cu129` | still hosted, but frozen — `cu128` pins you to torch 2.11 |

Two things that are easy to get wrong:

- **The arm64 CUDA wheels are SBSA datacenter builds.** `cu126` on arm64 covers
  only sm_80/sm_90 (A100, H100/GH200), and `cu129`/`cu130` also start at sm_80.
  Consumer-GPU coverage is x86_64 only, so a CUDA build of this image for
  `linux/arm64` is for datacenter hardware, not a laptop.
- **`cuda False` at build time is expected**, even for a CUDA build. The
  Dockerfile's closing smoke test runs during `docker build`, where no GPU is
  attached; `--gpus` is a run-time flag. Judge it from inside a running container:

```bash
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

On the host you also need the [NVIDIA Container
Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html);
without it the GPU never reaches the container no matter which wheels are inside.

The other route, and the one the [ai-agent template](../../templates/ai-agent)
takes, is to leave inference on the host behind an OpenAI compatible server and
keep the container as a client. That avoids the CUDA-in-a-container problem
entirely, at the cost of not being able to train in here.

## What downstream inherits, and what it does not

Consuming the image with `{"image": "ghcr.io/..."}` merges the config baked into
its `devcontainer.metadata` label, so the mount, `HF_TOKEN`, the forwarded ports,
`remoteUser` and the VS Code customizations all come along. Lifecycle commands
accumulate rather than override: the image's `postCreateCommand` runs first and
then yours, and you cannot suppress the inherited one.

Three things do **not** come along, and each needs a line in your own
`devcontainer.json`:

| Not inherited | What to do |
| --- | --- |
| `hostRequirements.gpu` | it is stored in the metadata but the CLI only reads it from the local config, so repeat `"hostRequirements": {"gpu": "optional"}` yourself, or pass `--gpu-availability all` |
| `runArgs`, `initializeCommand` | restate them in your config |
| `build.args` (`TORCH_INDEX`) | a build-time knob only; changing it means building from this Dockerfile rather than pulling the published image |

`"gpu": "optional"` is also narrower than it sounds: the CLI adds `--gpus all`
when **Docker reports an nvidia runtime**, not when a GPU is physically present.
A host with the toolkit installed but no card attached still gets `--gpus all`
and fails to start ([vscode-remote-release#10307](https://github.com/microsoft/vscode-remote-release/issues/10307)).

## Build arguments

| Arg | Default | Notes |
| --- | --- | --- |
| `TORCH_INDEX` | `cpu` | wheel index under `download.pytorch.org/whl/`; see the table above |
| `PYTHON_VERSION` | `3.12` | what the torch and transformers wheel matrix is best tested against |
| `BASE_IMAGE` / `BASE_TAG` | the published `base-almalinux:latest` | pin the tag for a reproducible build |
| `USERNAME` | `vscode` | must match the base image's remote user |
