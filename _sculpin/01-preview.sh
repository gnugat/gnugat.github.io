#!/bin/bash
# File: /_sculpin/01-preview.sh
# ──────────────────────────────────────────────────────────────────────────────
# Previews the changes:
# * generates the HTML from the markdown files
# * watches any changes and regenerates
# * creates a server on http://localhost:42999
#
# Usage:
#
# ```shell
# 01-preview.sh
# ```
# ──────────────────────────────────────────────────────────────────────────────

echo "  // Preview changes"

./vendor/bin/sculpin generate --watch --server --clean --no-interaction --port=42999
