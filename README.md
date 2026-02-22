# arc (Attach to Running Container)

A small CLI that opens a Docker container directly in Cursor (VS Code remote containers) using `vscode-remote://dev-container`.

It will start the container if it's stopped, and can optionally open a specific path inside the container (for example `/app`).

> **Note:** This script requires a Unix-like environment (Linux or macOS). Windows is not supported.

## Requirements

- Docker running
- Cursor installed, with the `cursor` CLI in your PATH
- Dev Containers extension installed in Cursor (<https://marketplace.cursorapi.com/items/?itemName=anysphere.remote-containers>)

## Installation

```bash
chmod +x arc
mv arc /usr/local/bin/arc
```

## Usage

```bash
arc [container-name] [path]
arc --help
```

- **container-name**: container name or ID.
- **path**: path inside the container to open (optional). E.g. `/app`, `/workspace`.

The script starts the container automatically if it's stopped.

Example:

```bash
arc my-container
arc my-container /app
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