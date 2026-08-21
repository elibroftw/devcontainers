#!/bin/bash

assert_successful_code bash --version
assert_successful_code pwsh --version
assert_successful_code python3 --version
assert_successful_code git --version
assert_successful_code nix --version
assert_successful_code just --version
assert_successful_code dotnet --version
assert_successful_code psql --version
assert_successful_code pi --version
assert_successful_code test -d "$HOME/.pi/agent/skills/find-skills"
assert_successful_code test -d "$HOME/.pi/agent/skills/dotnet-best-practices"
assert_successful_code test -d "$HOME/.pi/agent/skills/csharp-developer"
