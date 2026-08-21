#!/usr/bin/env bash
set -e

# LANGUAGES is the `languages` option, passed in uppercased by the devcontainer CLI
TESSERACT_LANGUAGES="${LANGUAGES:-eng}"

# poppler-utils: pdftotext, pdftoppm, pdfimages. Reach for `pdftotext -layout`
#   BEFORE any OCR. Most PDFs an agent meets already carry a text layer, and
#   OCR-ing one that does is slower, lossier, and more expensive than reading it.
#   Fall back to OCR only when pdftotext comes back empty. Biggest single win here.
# ImageMagick and unpaper: deskew, threshold, upscale. Preprocessing moves
#   tesseract accuracy more than any config flag does.
# zbar: zbarimg reads barcodes and QR codes, which models read badly and unreliably.
# ghostscript: ocrmypdf shells out to it at runtime.
# jq: runpodctl's installer and plenty of agent workflows want it; the base
#   image only ships yq.
dnf install -y poppler-utils ImageMagick unpaper zbar ghostscript jq

# runpodctl: manage RunPod GPU pods and serverless endpoints, for agents that
#   need GPU compute beyond the host. The installer requires root (feature
#   scripts run as root), verifies a sha256 checksum, puts the binary in
#   /usr/local/bin, and ships linux amd64 and arm64 like this image. Auth comes
#   from the RUNPOD_API_KEY env var, so no secret is baked into the image.
curl --proto '=https' --tlsv1.2 -fsSL https://cli.runpod.net | bash

# tesseract is in neither EPEL 9 nor EPEL 10, and neither is its leptonica
# dependency, so dnf is out. Nix is the escape hatch, the same route the base
# image uses for eza. Running as root installs into the default profile, which
# the base image already put on PATH.
#
# What tesseract buys you over just asking a model: `-c tsv` output gives
# per-word text with confidence scores and bounding boxes. Models are unreliable
# at exact pixel coordinates, so this is the tool for form fields and redaction.
#
# nixpkgs defaults to `enableLanguages = null`, meaning every language pack --
# gigabytes of traineddata -- so override it down to what was asked for.
export PATH="${PATH}:/nix/var/nix/profiles/default/bin"
# shellcheck disable=SC2086 # deliberate word splitting, one quoted nix string per language
NIX_LANGUAGES=$(printf '"%s" ' $TESSERACT_LANGUAGES)
nix profile install --impure --expr "
    let pkgs = (builtins.getFlake \"nixpkgs\").legacyPackages.\${builtins.currentSystem};
    in pkgs.tesseract.override { enableLanguages = [ ${NIX_LANGUAGES}]; }
"

# The python feature ships uv, but install it in case this feature is used alone
if ! command -v uv > /dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh
fi

# Feature scripts run as root, so put the tools somewhere shared instead of
# root's ~/.local where the remote user cannot reach them
export UV_TOOL_DIR=/usr/local/share/uv/tools
export UV_TOOL_BIN_DIR=/usr/local/bin

# ocrmypdf: wraps tesseract and ghostscript to graft a text layer onto a scanned
#   PDF in place. Agent-friendly because it is idempotent, and --skip-text makes
#   the "extract before you OCR" rule above automatic.
uv tool install ocrmypdf

# docling: PDF to markdown, when the goal is markdown-for-LLM rather than raw
#   text. Handles tables and reading order far better than tesseract does.
#   Pulls torch, so it is the heaviest thing installed by default here.
uv tool install docling

# chandra and surya are installed as CLIENTS. Both do their inference against a
# vLLM server that should live on the host, where the GPU and the weights are;
# the container just needs a URL. See NOTES.md for the host wiring.
#
# NOTE the package name. `chandra-ocr` is the OCR model; plain `chandra` on PyPI
#   is an unrelated project about image generator metadata.
# Base chandra-ocr targets the vLLM backend and does not pull torch -- that only
#   arrives with the [hf] extra, which is the in-process backend we do not want.
uv tool install chandra-ocr

# surya-ocr is the heavier of the two even in remote mode: torch and torchvision
#   are base dependencies rather than extras, because its detection stage runs on
#   torch locally whether or not a server is answering. Expect the image to grow.
uv tool install surya-ocr

# uv creates the tool dir root-owned, so let every user read and execute it
chmod -R a+rX "$UV_TOOL_DIR"
