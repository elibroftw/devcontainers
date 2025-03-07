#!/bin/bash

assert_successful_code bash --version
assert_successful_code pwsh --version
assert_successful_code python3 --version
assert_successful_code git --version
assert_successful_code nix --version
assert_successful_code just --version
