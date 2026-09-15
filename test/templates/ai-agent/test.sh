#!/bin/bash

assert_successful_code bash --version
assert_successful_code pwsh --version
assert_successful_code python3 --version
assert_successful_code git --version
assert_successful_code nix --version
assert_successful_code just --version
assert_successful_code yq --version
assert_successful_code rg --version
assert_successful_code eza --version
assert_successful_code zoxide --version
# `z` is a function from /etc/profile.d/zoxide.sh, not the binary, and ~/.bashrc
# runs after it and must not have clobbered its PROMPT_COMMAND hook
assert_successful_code bash -lc 'command -v z'
# shellcheck disable=SC2016 # the inner login shell expands it, that is the point
assert_successful_code bash -lc 'echo "$PROMPT_COMMAND" | grep -q __zoxide_hook'
assert_successful_code gh --version
assert_successful_code uv --version
assert_successful_code claude --version
assert_successful_code pi --version
assert_successful_code dsh --version
assert_successful_code openhands --version
assert_successful_code oh --version
assert_successful_code tmux -V
assert_successful_code pdftotext -v
assert_successful_code tesseract --version
assert_successful_code zbarimg --version
assert_successful_code ocrmypdf --version
assert_successful_code chandra --help
assert_successful_code surya_ocr --help
assert_successful_code runpodctl version
assert_successful_code hf version
assert_successful_code python -c 'import torch, torchvision, transformers, accelerate, librosa'
assert_successful_code test -d "$HOME/.pi/agent/skills/find-skills"
assert_successful_code test -d "$HOME/.claude/skills/find-skills"
assert_successful_code test -d "$HOME/.openhands/skills/find-skills"
assert_successful_code test -d "$HOME/.cache/huggingface"
