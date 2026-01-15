#!/bin/bash

# Automatically generate docs/index.md homepage file
# Usage: ./scripts/create-home.sh

set -e

DOCS_DIR="docs"
INDEX_FILE="$DOCS_DIR/index.md"

# Check if docs directory exists
if [ ! -d "$DOCS_DIR" ]; then
    echo "Error: $DOCS_DIR directory does not exist"
    exit 1
fi

# Get file creation date (cross-platform compatible)
get_creation_date() {
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: use birth time
        stat -f "%SB" -t "%Y-%m-%d" "$file"
    else
        # Linux: try to use birth time, fall back to mtime if not supported
        local birth_time=$(stat --format="%W" "$file" 2>/dev/null)
        if [ "$birth_time" != "0" ] && [ "$birth_time" != "-" ] && [ -n "$birth_time" ]; then
            date -d "@$birth_time" "+%Y-%m-%d"
        else
            # Fall back to modification time
            stat --format="%y" "$file" | cut -d' ' -f1
        fi
    fi
}

# Extract title from Markdown file (first # heading)
get_title() {
    local file="$1"
    local title=$(grep -m 1 "^# " "$file" | sed 's/^# //')
    if [ -z "$title" ]; then
        # If no title found, use filename
        title=$(basename "$file" .md)
    fi
    echo "$title"
}

# Collect all document information
declare -a docs_info=()

for file in "$DOCS_DIR"/*.md; do
    [ -f "$file" ] || continue

    filename=$(basename "$file")

    # Skip index.md
    if [ "$filename" = "index.md" ]; then
        continue
    fi

    date=$(get_creation_date "$file")
    title=$(get_title "$file")

    # Store as "date|title|filename" format for later sorting
    docs_info+=("$date|$title|$filename")
done

# Sort by date in descending order
IFS=$'\n' sorted_docs=($(sort -r -t'|' -k1 <<<"${docs_info[*]}"))
unset IFS

# Generate index.md content
cat > "$INDEX_FILE" << 'EOF'
# AI NOTEBOOK

A comprehensive repository of AI-generated technical guides. Each guide provides in-depth conceptual explanations, real-world use cases, and practical code examples to help developers master various technologies.

EOF

for doc in "${sorted_docs[@]}"; do
    IFS='|' read -r date title filename <<< "$doc"
    echo "- $date - [$title](./$filename)" >> "$INDEX_FILE"
done

echo ""
echo "Generated $INDEX_FILE"
echo "Total documents: ${#sorted_docs[@]}"
