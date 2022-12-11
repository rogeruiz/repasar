#!/bin/bash
set -e

git config --global --add safe.directory /github/workspace
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global gpg.format ssh
git config --global gpg.ssh.allowedSignersFile "${1}"

git verify-commit "${GITHUB_SHA}"
