#!/usr/bin/env bash

set -e

cd "${0%/*}/.."

if [[ -z "${NOTEST}" ]]; then
  echo "Running tests"
  bundle exec rake test
fi
