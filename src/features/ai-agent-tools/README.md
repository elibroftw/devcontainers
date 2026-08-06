
# AI Agent Tools (ai-agent-tools)

Document extraction and OCR tooling for coding agents: poppler-utils, tesseract, ImageMagick, unpaper, zbar, ocrmypdf, docling, and chandra and surya as clients for a host served vLLM

## Example Usage

```json
"features": {
    "ghcr.io/elibroftw/devcontainers/features/ai-agent-tools:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| languages | Space separated tesseract language packs. The nixpkgs default is every language, which is gigabytes of traineddata, so this is narrowed to English unless you widen it. | string | eng |

## When an agent should reach for these at all

A multimodal model already does OCR. These tools earn their place in the cases where
they beat handing the image to the model:

- **Volume** — thousands of pages where per-page inference costs real money
- **Determinism** — byte-identical output across runs
- **Coordinates** — bounding boxes for form fields, redaction, or table cells.
  Models are unreliable at exact pixel positions
- **No network** — air-gapped work

## Extract before you OCR

`pdftotext -layout` first, OCR only when it returns nothing. Most PDFs already carry a
text layer, so OCR-ing them is slower, lossier, and more expensive than reading it.
This one rule saves more time and tokens than any accuracy tuning.

## What each tool is for

| Tool | Source | Use |
| --- | --- | --- |
| `pdftotext`, `pdftoppm`, `pdfimages` | poppler-utils (dnf) | Text layer extraction, PDF to image, embedded image dump |
| `tesseract` | nix | OCR. `-c tsv` for per-word text, confidence, and bounding boxes |
| `magick`, `unpaper` | dnf | Deskew, threshold, upscale before OCR |
| `zbarimg` | dnf | Barcodes and QR codes |
| `ocrmypdf` | uv | Add a text layer to a scanned PDF in place, idempotently |
| `docling` | uv | PDF to markdown with tables and reading order |

`tesseract` comes from nix because neither it nor `leptonica` is packaged in EPEL 9 or
EPEL 10. The nixpkgs default builds every language pack, which is gigabytes, so the
`languages` option narrows it to English by default.

## chandra and surya: installed as clients, served from the host

Both beat tesseract badly on hard documents, and both are VLM based: they run against
a vLLM (or llama.cpp) server exposing an OpenAI-compatible endpoint rather than doing
inference in-process. So the client goes in the container and the server stays on the
host, where the GPU and the downloaded weights already are.

Two things to know about the install:

- The package is **`chandra-ocr`**. Plain `chandra` on PyPI is an unrelated project
  about image generator metadata. Base `chandra-ocr` targets the vLLM backend and
  stays light — torch only arrives with the `[hf]` extra, which is the in-process
  backend this image deliberately avoids.
- **`surya-ocr` pulls torch and torchvision as base dependencies**, not extras, even
  when you only ever point it at a remote server. Its detection stage runs on torch
  locally regardless. That is a couple of GB of image, and there is no lighter
  install path short of calling the server's HTTP API directly.

See the `ai-agent` template's NOTES for the host wiring, or in short:

```jsonc
"runArgs": ["--add-host=host.docker.internal:host-gateway"],
"remoteEnv": {
    "VLLM_API_BASE": "http://host.docker.internal:8000/v1",   // chandra
    "SURYA_INFERENCE_BACKEND": "vllm",
    "SURYA_INFERENCE_URL": "http://host.docker.internal:8001/v1"
}
```

There is also a licensing reason not to bake them in. The code is Apache-2.0, but the
model weights use a modified AI Pubs OpenRAIL-M licence: free for research, personal
use, and startups under $5M funding/revenue, and licensed from
[Datalab](https://www.datalab.to/pricing) past that. Installing pulls only the
Apache-2.0 code, so a build looks clean while the encumbered weights arrive on first
run inside whichever container the user happens to be in. Keeping the weights on the
host keeps that decision with the person who made it.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/elibroftw/devcontainers/blob/main/src/features/ai-agent-tools/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
