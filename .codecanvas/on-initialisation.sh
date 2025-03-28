#!/bin/bash
set -e

echo "Copy IDE settings"
.codecanvas/copyIdeaSettings.sh

echo "On container creation hook"
echo "Forward ports"
.codecanvas/copyIdeaProjectSettings.sh

echo "Install VNC server and noVNC"
.codecanvas/vnc/vnc-config.sh
echo "Installed VNC server and noVNC"
