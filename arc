#!/usr/bin/env bash
set -e
# arc - Attach to Running Container
# Usage:
#   arc open  <container-name> [path-inside-container]
#   arc build <workspace-path> [path-inside-container]

# --- Helpers ---
usage() {
  echo "Usage:"
  echo "  arc open  <container-name> [path-inside-container]"
  echo "  arc build <workspace-path> [path-inside-container]"
  echo ""
  echo "Commands:"
  echo "  open    Attach the selected IDE to an already running (or stopped) container"
  echo "  build   Provision and open a container from a devcontainer.json"
  echo ""
  echo "Environment:"
  echo "  ARC_PREFERRED_IDE   vscode (default) or cursor; an empty value uses vscode"
  echo ""
  echo "Examples:"
  echo "  arc open  my-container              # attach to container"
  echo "  arc open  my-container /app         # attach and open /app"
  echo "  arc build ~/projects/my-app         # provision and open project"
  echo "  arc build ~/projects/my-app /app    # provision and open /app"
  exit 1
}

error() {
  echo "Error: $1" >&2
  exit 1
}

# Select the CLI before any container operation.
select_ide() {
  case "${ARC_PREFERRED_IDE:-vscode}" in
    vscode) IDE_CLI="code" ;;
    cursor) IDE_CLI="cursor" ;;
    *) error "Invalid ARC_PREFERRED_IDE '${ARC_PREFERRED_IDE}'. Expected vscode or cursor." ;;
  esac
  command -v "$IDE_CLI" &>/dev/null \
    || error "$IDE_CLI CLI not found. Make sure the selected IDE is installed and '$IDE_CLI' is in your PATH."
}

# --- Parse subcommand ---
if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then
  usage
fi

SUBCOMMAND="$1"
shift

# =============================================================================
# arc open <container-name> [path]
# =============================================================================
cmd_open() {
  local CONTAINER_NAME="${1:-}"
  local OPEN_PATH="${2:-}"

  command -v docker &>/dev/null  || error "Docker not found. Is Docker installed and running?"
  select_ide

  [[ -z "$CONTAINER_NAME" ]] && error "Missing container name. Run: arc open <container-name> [path]"

  # Check container exists
  local CONTAINER_ID
  CONTAINER_ID=$(docker inspect --format '{{.Id}}' "$CONTAINER_NAME" 2>/dev/null) \
    || error "Container '$CONTAINER_NAME' not found."

  # Start container if not running
  local CONTAINER_STATUS
  CONTAINER_STATUS=$(docker inspect --format '{{.State.Status}}' "$CONTAINER_NAME")
  if [[ "$CONTAINER_STATUS" != "running" ]]; then
    echo "Container '$CONTAINER_NAME' is $CONTAINER_STATUS. Starting it..."
    docker start "$CONTAINER_NAME" > /dev/null
    echo "Container started."
    CONTAINER_ID=$(docker inspect --format '{{.Id}}' "$CONTAINER_NAME")
  fi

  local SHORT_ID="${CONTAINER_ID:0:12}"
  local JSON_SPEC="{\"settingType\":\"container\",\"containerId\":\"${SHORT_ID}\"}"
  local AUTHORITY="dev-container"
  if [[ "$IDE_CLI" == "code" ]]; then
    AUTHORITY="attached-container"
    JSON_SPEC="{\"containerName\":\"${CONTAINER_ID}\"}"
  fi
  local ENCODED_SPEC
  ENCODED_SPEC=$(printf '%s' "$JSON_SPEC" | od -A n -t x1 | tr -d '[\n\t ]')
  local URI="vscode-remote://${AUTHORITY}+${ENCODED_SPEC}${OPEN_PATH}"

  echo "Container: $CONTAINER_NAME ($SHORT_ID)"
  echo "Path:      ${OPEN_PATH:-"(none)"}"
  echo ""

  "$IDE_CLI" --folder-uri "$URI"
}

# =============================================================================
# arc build <workspace-path> [path]
# =============================================================================
cmd_build() {
  local WORKSPACE_PATH="${1:-}"
  local OPEN_PATH="${2:-}"

  select_ide

  [[ -z "$WORKSPACE_PATH" ]] && error "Missing workspace path. Run: arc build <workspace-path> [path]"

  # Resolve to absolute path
  WORKSPACE_PATH=$(cd "$WORKSPACE_PATH" 2>/dev/null && pwd) \
    || error "Workspace path '$1' not found."

  # Locate devcontainer.json
  local DEVCONTAINER_PATH=""
  local CANDIDATES=(
    "${WORKSPACE_PATH}/.devcontainer/devcontainer.json"
    "${WORKSPACE_PATH}/.devcontainer.json"
  )

  for CANDIDATE in "${CANDIDATES[@]}"; do
    if [[ -f "$CANDIDATE" ]]; then
      DEVCONTAINER_PATH="$CANDIDATE"
      break
    fi
  done

  [[ -z "$DEVCONTAINER_PATH" ]] && error "No devcontainer.json found in '$WORKSPACE_PATH'. Expected at .devcontainer/devcontainer.json or .devcontainer.json"

  local JSON_SPEC="{\"settingType\":\"config\",\"workspacePath\":\"${WORKSPACE_PATH}\",\"devcontainerPath\":\"${DEVCONTAINER_PATH}\"}"
  if [[ "$IDE_CLI" == "code" ]]; then
    JSON_SPEC="{\"hostPath\":\"${WORKSPACE_PATH}\"}"
  fi
  local ENCODED_SPEC
  ENCODED_SPEC=$(printf '%s' "$JSON_SPEC" | od -A n -t x1 | tr -d '[\n\t ]')
  local URI="vscode-remote://dev-container+${ENCODED_SPEC}${OPEN_PATH}"

  echo "Workspace:    $WORKSPACE_PATH"
  echo "Devcontainer: $DEVCONTAINER_PATH"
  echo "Path:         ${OPEN_PATH:-"(none)"}"
  echo ""

  "$IDE_CLI" --folder-uri "$URI"
}

# =============================================================================
# Route subcommand
# =============================================================================
case "$SUBCOMMAND" in
  open)  cmd_open  "$@" ;;
  build) cmd_build "$@" ;;
  *)     error "Unknown command '$SUBCOMMAND'. Run: arc --help" ;;
esac
