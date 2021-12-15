#!/usr/bin/env bash

set -e

cd "${0%/*}/.."

if [[ -z "${NOCOP}" ]]; then
  echo "Running rubocop"
  # bundle exec rubocop
  bundle exec rubocop --force_exclusion $(git status -su | awk '{sub(/^(R.*-> )|[ MA?]+/,"")};1' | awk '!/^D/')
fi
