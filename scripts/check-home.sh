#!/bin/bash

# Validate that docs/index.md is up to date
# Used for pre-push hook

set -e

INDEX_FILE="docs/index.md"
TEMP_FILE=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

# Check if index.md exists
if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: $INDEX_FILE does not exist"
    echo "Please run npm run create:home to generate the index file first"
    exit 1
fi

# Save current content
cp "$INDEX_FILE" "$TEMP_FILE"

# Regenerate index.md (silent mode)
npm run create:home --silent > /dev/null 2>&1

# Compare content
if ! diff -q "$TEMP_FILE" "$INDEX_FILE" > /dev/null 2>&1; then
    # Restore original content
    cp "$TEMP_FILE" "$INDEX_FILE"
    echo "Error: docs/index.md content is not up to date"
    echo "Please run npm run create:home to update the index before pushing"
    exit 1
fi

# Restore original content (preserve file timestamp)
cp "$TEMP_FILE" "$INDEX_FILE"

echo "index.md validation passed"
exit 0
