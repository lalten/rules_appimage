#!/bin/bash

set -euo pipefail

doc_file="$1"

if [[ ! -f "$doc_file" ]]; then
  echo "ERROR: Documentation file not found: $doc_file"
  exit 1
fi

if [[ ! -s "$doc_file" ]]; then
  echo "ERROR: Documentation file is empty: $doc_file"
  exit 1
fi

# Optional: Add a grep check for some expected content
# if ! grep -q "some expected string" "$doc_file"; then
#   echo "ERROR: Expected content not found in $doc_file"
#   exit 1
# fi

echo "Smoke test passed: $doc_file exists and is not empty."
exit 0
