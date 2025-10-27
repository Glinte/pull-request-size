#!/bin/bash
# Script to help format the private key for environment variables

set -e

echo "========================================"
echo "Private Key Formatter for .env files"
echo "========================================"
echo ""

if [ $# -eq 0 ]; then
    echo "Usage: ./scripts/format-private-key.sh <path-to-pem-file>"
    echo ""
    echo "Example:"
    echo "  ./scripts/format-private-key.sh my-app.2024-10-27.private-key.pem"
    echo ""
    exit 1
fi

PEM_FILE="$1"

if [ ! -f "$PEM_FILE" ]; then
    echo "Error: File not found: $PEM_FILE"
    exit 1
fi

echo "Processing: $PEM_FILE"
echo ""
echo "=========================================="
echo "Formatted private key for .env file:"
echo "=========================================="
echo ""
echo -n 'PRIVATE_KEY="'
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "$PEM_FILE"
echo '"'
echo ""
echo "=========================================="
echo ""
echo "Copy the line above (including PRIVATE_KEY=\"...\") to your .env file"
echo ""
echo "Alternative: Base64 encoded (some platforms prefer this):"
echo "=========================================="
echo ""
echo -n 'PRIVATE_KEY_BASE64="'
base64 < "$PEM_FILE" | tr -d '\n'
echo '"'
echo ""
echo "=========================================="
