# agent-container

A container for running AI coding agents ([Claude Code](https://www.anthropic.com/claude-code) and [opencode](https://opencode.ai)) in isolation from the host. Only a persistent home folder and one project folder are visible inside the container.

## Contents

- Debian trixie-slim
- Node.js 24 (official binary), Python 3, build-essential, git, ripgrep, fd, jq, tmux, vim, nano, `ps`/`top`
- `claude` and `opencode`, installed globally via npm
- zsh with oh-my-zsh and the spaceship prompt (installed in `/opt/oh-my-zsh`)
- Non-root user `agent`, whose UID/GID match the host user

## Files

| File | Purpose |
| --- | --- |
| `Containerfile` | Image definition |
| `compose.yaml` | Service definition: build args, mounts, environment |
| `compose.podman.yaml` | Podman-only override (`userns_mode: keep-id`) |
| `run.sh` | Launcher: picks the engine, builds the image if missing, starts the container |
| `zshrc` | Global zsh config, installed as `/etc/zsh/zshrc` |
| `home/` | Host folder mounted as `/home/agent` (created on first run) |

## Requirements

- podman with `podman compose`, or docker with the compose plugin. `run.sh` prefers podman and falls back to docker.

## Usage

```sh
# Run for a project folder (argument)
./run.sh ~/projects/foo

# Or via environment variable
WORKSPACE=~/projects/foo ./run.sh

# No argument: uses the current directory
./run.sh .

# Run a command instead of an interactive shell
./run.sh ~/projects/foo claude
./run.sh ~/projects/foo opencode
```

The image is built automatically on first run. To rebuild (for example, to pick up new package or agent versions):

```sh
podman compose -f compose.yaml -f compose.podman.yaml build --no-cache
# docker: docker compose build --no-cache
```

Set `ENGINE=docker` (or `ENGINE=podman`) to force an engine.

### Mounts

| Host | Container |
| --- | --- |
| `./home` | `/home/agent` |
| Workspace folder | `/workspace` (working directory) |

Everything the agents store (credentials, config, shell history, the VS Code server) is kept in `./home` and persists across runs.

### Container name

The container is named `agent-<workspace folder name>`, for example `agent-foo`. Only one container per workspace folder can run at a time.

### Credentials

`ANTHROPIC_API_KEY` is passed through from the host environment if set. Otherwise, log in inside the container; the login is saved in `./home`.

### Shell customisation

Put personal zsh settings in `home/.zshrc.local`. It is sourced at the end of the global config.

The spaceship prompt works best with a Nerd Font or Powerline-capable font in the host terminal.

## Connecting from VS Code

1. Install the Dev Containers extension (`ms-vscode-remote.remote-containers`).
2. With podman, set `dev.containers.dockerPath` to `podman` and run `systemctl --user enable --now podman.socket`.
3. Start the container with `./run.sh <folder>`.
4. Run **Dev Containers: Attach to Running Container...** and select `agent-<folder>`.
5. Open `/workspace` folder in VS code.

The container uses `--rm`, so keep the `run.sh` terminal open while VS Code is attached.

## Notes

- Podman runs with `--userns=keep-id` (see `compose.podman.yaml`) so files created in the mounts are owned by your host user. Docker needs no equivalent.
- Mounts use the `:Z` option to relabel files for SELinux. This changes the SELinux label of the host `home` and workspace folders.
- The agents have full read/write access to the mounted workspace and `home` (not your host `$HOME`, but the `home` folder in this project). They are not sandboxed from those folders.
