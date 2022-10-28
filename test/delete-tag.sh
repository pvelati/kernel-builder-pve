#!/bin/bash

set -eaux

git tag -d $1
git push origin :$1

# export GH_TOKEN=
# gh release list | sed 's/|/ /' | awk '{print $1, $8}' | while read -r line; do gh release delete -y "$line"; done
# gh api repos/pvelati/kernel-builder-pve/actions/runs --paginate -q '.workflow_runs[] | select(.head_branch != "master") | "\(.id)"' | xargs -I % gh api repos/pvelati/kernel-builder-pve/actions/runs/% -X DELETE
