#!/usr/bin/env bash
# Usage: WORKSPACE=/path/to/project ./run.sh [command...]
#    or: ./run.sh /path/to/project [command...]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${ENGINE:-}" ]]; then
    if command -v podman >/dev/null 2>&1; then
        ENGINE=podman
    elif command -v docker >/dev/null 2>&1; then
        ENGINE=docker
    else
        echo "error: neither podman nor docker is installed" >&2
        exit 1
    fi
fi

if [[ $# -gt 0 && -d "$1" ]]; then
    WORKSPACE="$1"
    shift
fi
export WORKSPACE="$(cd "${WORKSPACE:-$PWD}" && pwd)"
export USER_UID="$(id -u)"
export USER_GID="$(id -g)"

mkdir -p "$SCRIPT_DIR/home"

COMPOSE=("$ENGINE" compose -f "$SCRIPT_DIR/compose.yaml")
if [[ "$ENGINE" == podman ]]; then
    COMPOSE+=(-f "$SCRIPT_DIR/compose.podman.yaml")
fi

if ! "$ENGINE" image inspect agent-container >/dev/null 2>&1; then
    "${COMPOSE[@]}" build
fi

FOLDER="$(basename "$WORKSPACE")"
NAME="agent-${FOLDER//[^A-Za-z0-9_.-]/-}"

exec "${COMPOSE[@]}" run --rm --name "$NAME" agent "$@"
