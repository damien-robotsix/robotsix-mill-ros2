#!/usr/bin/env bash
# .devcontainer/post-create.sh — ROS2 workspace lifecycle hook
# Runs after the devcontainer is created.
set -euo pipefail

echo "=== robotsix-mill-ros2 post-create ==="

# --- ccache setup ---
# The ccache cache directory is mounted as a named volume at /home/ros/.ccache.
# Ensure correct ownership (volume may be created root-owned on first launch).
mkdir -p /home/ros/.ccache
sudo chown -R "$(whoami):$(whoami)" /home/ros/.ccache

# Verify ccache is on PATH and functional
if command -v ccache &>/dev/null; then
    echo "[ccache] version: $(ccache --version | head -1)"
    echo "[ccache] cache dir:  $(ccache --get-config cache_dir)"
    echo "[ccache] max size:   $(ccache --get-config max_size)"
else
    echo "[ccache] WARNING: ccache not found on PATH" >&2
fi

# --- ROS2 workspace bootstrap ---
# Import repositories declared in repos.yaml
vcs import src < repos.yaml

# Install system dependencies
rosdep update
rosdep install --from-paths src --ignore-src -y

# Fix permissions on any root-owned files in the workspace
sudo chown -R "$(whoami):$(whoami)" .

echo "=== post-create complete ==="