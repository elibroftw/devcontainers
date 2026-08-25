# The AlmaLinux base image plus a ai/torch stack that is ready on first boot.
ARG BASE_IMAGE=ghcr.io/elibroftw/devcontainers/images/base-almalinux
ARG BASE_TAG=latest
FROM ${BASE_IMAGE}:${BASE_TAG}

SHELL ["/bin/bash", "-c"]
# cu128 / cu129
# cu126: GTX 750 through RTX 40xx
# cu130: GTX 16xx through RTX 50xx
ARG TORCH_INDEX=cpu
ARG PYTHON_VERSION=3.12
ARG USERNAME=vscode

RUN curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

ENV UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python
ENV UV_PYTHON_BIN_DIR=/usr/local/bin
RUN uv python install "${PYTHON_VERSION}" && chmod -R a+rX "${UV_PYTHON_INSTALL_DIR}"

ENV VIRTUAL_ENV=/opt/ai
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
RUN mkdir -p "${VIRTUAL_ENV}" && chown ${USERNAME}: "${VIRTUAL_ENV}"

# as the user, so no chown -R afterwards copies the whole venv into a second layer
USER ${USERNAME}

# --seed so `pip install` lands here too, not in the distro python further down PATH
RUN uv venv --seed --no-cache --python "${PYTHON_VERSION}" "${VIRTUAL_ENV}"

RUN uv pip install --no-cache --index-url "https://download.pytorch.org/whl/${TORCH_INDEX}" \
    torch \
    torchvision

RUN uv pip install --no-cache \
    accelerate \
    transformers \
    librosa \
    huggingface_hub

USER root

ENV HF_HOME=/home/${USERNAME}/.cache/huggingface
# torchvision's weights are not Hub downloads and would otherwise land in an
# unmounted ~/.cache/torch
ENV TORCH_HOME=${HF_HOME}/torch
RUN mkdir -p "${TORCH_HOME}" && chown -R ${USERNAME}: "/home/${USERNAME}/.cache"

RUN python -c "import torch, torchvision, transformers, accelerate, librosa; \
    print(f'torch {torch.__version__} | torchvision {torchvision.__version__} | transformers {transformers.__version__} | accelerate {accelerate.__version__} | librosa {librosa.__version__} | cuda {torch.cuda.is_available()}')"
