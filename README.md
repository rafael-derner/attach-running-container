# arc (Attach to Running Container)

A small CLI that opens a Docker container directly in VS Code or Cursor using `vscode-remote://dev-container`.

It will start the container if it's stopped, and can optionally open a specific path inside the container (for example `/app`).

> **Note:** This script requires a Unix-like environment (Linux or macOS). Windows is not supported.

## Requirements

- Docker running
- VS Code with the `code` CLI in your PATH, or Cursor with the `cursor` CLI
- Dev Containers extension installed in the selected IDE (Microsoft Dev Containers for VS Code, or <https://marketplace.cursorapi.com/items/?itemName=anysphere.remote-containers> for Cursor)

## Preferred IDE

Set `ARC_PREFERRED_IDE` to `vscode` or `cursor`. When unset or empty, it defaults to `vscode`. Any other value is rejected before starting or opening a container. The selected IDE's CLI must be in your PATH; arc does not fall back to another IDE.

```bash
export ARC_PREFERRED_IDE=cursor

# Build
arc build ~/projects/my-app /app

# Or open
arc open my-container /app
```

To persist the preference, add the export to your shell configuration (for example, `~/.zshrc`). This setting applies to both `open` and `build`.

## Installation

```bash
chmod +x arc
mv arc /usr/local/bin/arc
```

## Usage

```bash
arc open <container-name> [path]
arc build <workspace-path> [path]
arc --help
```

- **container-name**: container name or ID.
- **path**: path inside the container to open (optional). E.g. `/app`, `/workspace`.

The script starts the container automatically if it's stopped.

Example:

```bash
arc open my-container
arc open my-container /app
arc build ~/projects/my-app /app
```

---

## Shell Completion (Zsh)

Zsh completion file. When you type `arc` and press Tab, it completes the container name and then suggests paths based on:

- the container working directory (from `docker inspect`)
- subfolders inside the working directory (if the container is running)
- common directories like `/app`, `/workspace`, `/root`, etc.

### Requirements

- zsh or Oh-my-zsh installed
- Plugin zsh-completions (<https://github.com/zsh-users/zsh-completions>)

### Setup

1. Put `_arc_zsh_completion` where the plugin's `src` folder is located. E.g. `~/.oh-my-zsh/custom/plugins/zsh-completions/src/`

```bash
cp _arc_zsh_completion ~/.oh-my-zsh/custom/plugins/zsh-completions/src/
```

2. Reload your shell:

```bash
source ~/.zshrc
```