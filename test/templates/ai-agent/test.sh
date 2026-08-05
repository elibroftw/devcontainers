#!/bin/bash

assert_successful_code bash --version
assert_successful_code pwsh --version
assert_successful_code python3 --version
assert_successful_code git --version
assert_successful_code nix --version
assert_successful_code just --version
assert_successful_code yq --version
assert_successful_code rg --version
assert_successful_code gh --version
assert_successful_code uv --version
assert_successful_code claude --version
