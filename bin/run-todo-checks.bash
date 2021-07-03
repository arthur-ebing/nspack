#!/usr/bin/env bash

set -e

cd "${0%/*}/.."

git grep -I -l TODO | xargs -n1 git blame -f -n -w | grep TODO | grep "$(git config user.name)" | sed "s/.\{9\}//"
