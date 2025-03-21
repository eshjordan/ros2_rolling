#!/bin/bash

# rm -rf ./build ./install ./log

wget -O ros2.repos https://raw.githubusercontent.com/ros2/ros2/rolling/ros2.repos
rosinstall_generator --rosdistro rolling --deps --upstream --format repos desktop_full > desktop_full.repos
# rosinstall_generator --rosdistro rolling --deps --upstream --format repos --from-path ~/colcon_ws/src --deps-only > colcon_ws.repos

# Find repository names in ros2.repos, and remove matching entries from desktop_full.repos
# Repository names in ros2.repos start with two spaces, followed by a directory and a slash
#   ament/ament_cmake:
#     type: git
#     url: https://github.com/ament/ament_cmake.git
#     version: rolling

# Find repo names in ros2.repos
REPO_NAMES=$(sed -r -n 's/  [0-9A-Za-z_-]+\/(.*):/\1/p' ros2.repos)

# Append some manual exclusions because the names don't match
REPO_NAMES="${REPO_NAMES} fastcdr fastdds"

# Remove lines starting with repo names, plus the following 3 lines from desktop_full.repos
for REPO_NAME in $REPO_NAMES; do
  sed -i "/^  ${REPO_NAME}:/,+3d" desktop_full.repos
done

mkdir -p src

# Import
vcs custom src --args remote update
vcs import src < ros2.repos
#vcs import src < desktop_full.repos
vcs import src < custom.repos
vcs pull src

wget -O src/ros/urdfdom_headers/package.xml https://raw.github.com/ros2-gbp/urdfdom_headers-release/debian/rolling/noble/urdfdom_headers/package.xml

rosdep install -r -n --os=ubuntu:noble --ignore-src --default-yes --from-path src || true
colcon build --symlink-install # --executor sequential
