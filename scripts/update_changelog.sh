#!/bin/bash
# update_changelog.sh - Generate/update CHANGES.md using git-cliff
# Requires: git-cliff (https://github.com/orhun/git-cliff)

if ! command -v git-cliff &> /dev/null
then
    echo "git-cliff could not be found. Please install it from https://github.com/orhun/git-cliff/releases"
    exit 1
fi

git cliff -o CHANGES.md

echo "CHANGES.md updated successfully."
