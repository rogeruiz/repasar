#!/bin/bash
set -e

git config --global --add safe.directory /github/workspace
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global gpg.format ssh
git config --global gpg.ssh.allowedSignersFile "${1}"

if git verify-commit "${GITHUB_SHA}" &>/dev/null
then
  echo "Commit ${GITHUB_SHA} is verified successfully!"
  git verify-commit "${GITHUB_SHA}"
  echo "verified=true" >> "${GITHUB_OUTPUT}"
else
  echo "Failed to verify the commit ${GITHUB_SHA}."
  echo "verified=false" >> "${GITHUB_OUTPUT}"
  if [[ ${2} == 'true' ]]
  then
    exit 1
  fi
fi
