#!/bin/bash

set -eaux

export GH_TOKEN=$1
gh api repos/pvelati/kernel-builder-pve/actions/runs --paginate -q '.workflow_runs[] | select(.head_branch != "master") | "\(.id)"' | xargs -I % gh api repos/pvelati/kernel-builder-pve/actions/runs/% -X DELETE
