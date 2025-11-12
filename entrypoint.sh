#!/bin/bash
set -e

git config --global --add safe.directory /github/workspace
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global gpg.format ssh
git config --global gpg.ssh.allowedSignersFile "${1}"

# Detect PR context
if [[ "$GITHUB_EVENT_NAME" == "pull_request" || "$GITHUB_EVENT_NAME" == "pull_request_target" ]]; then
  echo "Detected PR context. Verifying all commits in the PR."
  # Extract PR number from event payload
  if command -v jq &>/dev/null; then
    PR_NUMBER=$(jq '.number' "$GITHUB_EVENT_PATH")
  else
    PR_NUMBER=$(grep '"number":' "$GITHUB_EVENT_PATH" | head -1 | sed 's/[^0-9]*//g')
  fi
  echo "PR number: $PR_NUMBER"
  # Fetch all commit SHAs in the PR
  COMMITS_JSON=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/commits")
  if command -v jq &>/dev/null; then
    SHAS=($(echo "$COMMITS_JSON" | jq -r '.[].sha'))
  else
    SHAS=($(echo "$COMMITS_JSON" | grep '"sha":' | awk -F '"' '{print $4}'))
  fi
  FAILED_SHAS=()
  for sha in "${SHAS[@]}"; do
    if git verify-commit "$sha" &>/dev/null; then
      echo "Commit $sha is verified successfully!"
      git verify-commit "$sha"
    else
      echo "Failed to verify the commit $sha."
      FAILED_SHAS+=("$sha")
    fi
  done
  if [[ ${#FAILED_SHAS[@]} -eq 0 ]]; then
    echo "All commits in PR are verified."
    echo "verified=true" >> "${GITHUB_OUTPUT}"
  else
    echo "The following commits failed verification: ${FAILED_SHAS[*]}"
    echo "verified=false" >> "${GITHUB_OUTPUT}"
    if [[ ${2} == 'true' ]]; then
      exit 1
    fi
  fi
else
  # Fallback: verify latest commit as before
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
fi
