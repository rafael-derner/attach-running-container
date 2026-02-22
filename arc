#!/usr/bin/env bash

set -e

# arc - Attach to Running Container
# Usage: arc [container-name] [path]

OPEN_PATH=""

# --- Helpers ---
usage() {
  echo "Usage: arc [container-name] [path-inside-container]"
  echo ""
  echo "  container-name          Name or ID of a Docker container (started if stopped)"
  echo "  path-inside-container   Path to open inside the container (optional)"
  echo ""
  echo "Example:"
  echo "  arc my-container                 # attach to container"
  echo "  arc my-container /app            # attach and open /app"
  exit 1
}

error() {
  echo "Error: $1" >&2
  exit 1
}

# --- Parse args ---
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
fi

CONTAINER_NAME="$1"
OPEN_PATH="${2:-}"

# --- Check dependencies ---
command -v docker &>/dev/null || error "Docker not found. Is Docker installed and running?"
command -v cursor &>/dev/null || error "cursor CLI not found. Make sure Cursor is installed and 'cursor' is in your PATH."

# --- Require a container name ---
if [[ -z "$CONTAINER_NAME" ]]; then
  error "Missing container name. Run: arc <container-name> [path-inside-container]"
fi

# --- Check container exists ---
CONTAINER_ID=$(docker inspect --format '{{.Id}}' "$CONTAINER_NAME" 2>/dev/null) \
  || error "Container '$CONTAINER_NAME' not found."

# --- Start container if not running ---
CONTAINER_STATUS=$(docker inspect --format '{{.State.Status}}' "$CONTAINER_NAME")
if [[ "$CONTAINER_STATUS" != "running" ]]; then
  echo "Container '$CONTAINER_NAME' is $CONTAINER_STATUS. Starting it..."
  docker start "$CONTAINER_NAME" > /dev/null
  echo "Container started."
  # Refresh ID after start
  CONTAINER_ID=$(docker inspect --format '{{.Id}}' "$CONTAINER_NAME")
fi

# --- Build JSON spec and hex-encode it ---
SHORT_ID="${CONTAINER_ID:0:12}"
JSON_SPEC="{\"settingType\":\"container\",\"containerId\":\"${SHORT_ID}\"}"
ENCODED_SPEC=$(printf '%s' "$JSON_SPEC" | od -A n -t x1 | tr -d '[\n\t ]')

# --- Build URI ---
URI="vscode-remote://dev-container+${ENCODED_SPEC}${OPEN_PATH}"

echo "Container: $CONTAINER_NAME ($SHORT_ID)"
echo "Path: ${OPEN_PATH:-"(none)"}"
echo "URI: $URI"
echo ""

cursor --folder-uri "$URI"