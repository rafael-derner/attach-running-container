#!/usr/bin/env bash

set -e

# arc - Attach to Running Container
# Usage: arc [container-name] [path]
#        arc --list

OPEN_PATH=""

# --- Helpers ---
usage() {
  echo "Usage: arc [container-name] [path-inside-container]"
  echo "       arc --list"
  echo ""
  echo "  container-name          Name or ID of a Docker container (started if stopped)"
  echo "  path-inside-container   Path to open inside the container (optional)"
  echo "  --list, -l              List all containers and exit"
  echo ""
  echo "  If no container name is provided and fzf is installed, an interactive"
  echo "  picker will be shown. Otherwise, all containers are listed."
  echo ""
  echo "Example:"
  echo "  arc                              # interactive picker (requires fzf)"
  echo "  arc my-container                 # attach to container"
  echo "  arc my-container /app            # attach and open /app"
  echo "  arc --list                       # list all containers"
  exit 1
}

error() {
  echo "Error: $1" >&2
  exit 1
}

list_containers() {
  echo "Docker containers:"
  echo ""
  docker ps --all --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
}

# --- Parse args ---
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
fi

if [[ "$1" == "--list" || "$1" == "-l" ]]; then
  list_containers
  exit 0
fi

CONTAINER_NAME="$1"
OPEN_PATH="${2:-}"

# --- Check dependencies ---
command -v docker &>/dev/null || error "Docker not found. Is Docker installed and running?"
command -v cursor &>/dev/null || error "cursor CLI not found. Make sure Cursor is installed and 'cursor' is in your PATH."

# --- Interactive picker if no container name provided ---
if [[ -z "$CONTAINER_NAME" ]]; then
  if command -v fzf &>/dev/null; then
    CONTAINER_NAME=$(docker ps --all --format "{{.Names}}\t{{.Image}}\t{{.Status}}" \
      | fzf --prompt="Select container: " \
            --header="NAME                IMAGE               STATUS" \
            --delimiter="\t" \
            --with-nth=1,2,3 \
      | awk '{print $1}')
    [[ -n "$CONTAINER_NAME" ]] || exit 0
  else
    echo "Tip: install fzf for interactive container selection."
    echo ""
    list_containers
    exit 0
  fi
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
