#!/bin/bash
set -e

output=$(husarnet-dds singleshot) || true
if [[ "$HUSARNET_DDS_DEBUG" == "TRUE" ]]; then
  echo "$output"
fi

# setup ros environment
source "/opt/ros/$ROS_DISTRO/setup.bash"

if [ -z "$USER" ]; then
    export USER=root
elif ! id "$USER" &>/dev/null; then
    useradd -ms /bin/bash "$USER"
fi

test -f "/ros2_ws/install/setup.bash" && source "/ros2_ws/install/setup.bash"
gosu $USER bash -c 'ros2 run healthcheck_pkg healthcheck_node &'

if [ $# -eq 0 ]; then
    exec gosu $USER /bin/bash
else
    exec gosu $USER "$@"
fi
