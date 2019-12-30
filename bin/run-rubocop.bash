#!/usr/bin/env bash

set -e

cd "${0%/*}/.."

echo "Running rubocop"
# bundle exec rubocop
bundle exec rubocop $(git status -su | awk '{sub(/^(R.*-> )|[ M?]+/,"")};1' | awk '!/^D/')
