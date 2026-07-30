#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  printf 'Usage: %s SOURCE_DIRECTORY DESTINATION_DIRECTORY\n' "$0" >&2
  exit 2
fi

source_dir="${1%/}"
destination_dir="${2%/}"

if [[ ! -d "$source_dir" ]]; then
  printf 'Source directory does not exist: %s\n' "$source_dir" >&2
  exit 1
fi

if [[ ! -d "$destination_dir" ]]; then
  printf 'Destination directory does not exist: %s\n' "$destination_dir" >&2
  exit 1
fi

printf 'Checksum dry run: %s -> %s\n' "$source_dir" "$destination_dir"
printf 'This can take hours and will not modify either directory.\n\n'

rsync -aHAXxnc \
  --numeric-ids \
  --itemize-changes \
  --stats \
  "$source_dir/" \
  "$destination_dir/"
