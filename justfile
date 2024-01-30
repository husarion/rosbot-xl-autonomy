set dotenv-load

[private]
alias husarnet := connect-husarnet
[private]
alias flash := flash-firmware
[private]
alias rosbot := start-rosbot
[private]
alias pc := start-pc
[private]
alias teleop := run-teleop
[private]
alias teleop-docker := run-teleop-docker

[private]
default:
  @just --list --unsorted

_install-rsync:
    #!/bin/bash
    if ! command -v rsync &> /dev/null; then
        if [ "$EUID" -ne 0 ]; then
            echo "Please run as root to install dependencies"
            exit 1
        fi

        sudo apt update && sudo apt install -y rsync
    fi

_install-yq:
    #!/bin/bash
    if ! command -v /usr/bin/yq &> /dev/null; then
        if [ "$EUID" -ne 0 ]; then
            echo "Please run as root to install dependencies"
            exit 1
        fi

        YQ_VERSION=v4.35.1
        ARCH=$(arch)

        if [ "$ARCH" = "x86_64" ]; then
            YQ_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ]; then
            YQ_ARCH="arm64"
        else
            YQ_ARCH="$ARCH"
        fi

        curl -L https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH} -o /usr/bin/yq
        chmod +x /usr/bin/yq
        echo "yq installed successfully!"
    fi

# connect to Husarnet VPN network
connect-husarnet joincode hostname:
    #!/bin/bash
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
    fi
    if ! command -v husarnet > /dev/null; then
        echo "Husarnet is not installed. Installing now..."
        curl https://install.husarnet.com/install.sh | sudo bash
    fi
    husarnet join {{joincode}} {{hostname}}

# flash the proper firmware for STM32 microcontroller in ROSbot XL
flash-firmware: _install-yq
    #!/bin/bash
    if [ "$EUID" -ne 0 ]; then
        echo "Stopping all running containers"
        docker ps -q | xargs -r docker stop

        echo "Flashing the firmware for STM32 microcontroller in ROSbot"
        docker run \
            --rm -it \
            --device /dev/ttyUSBDB \
            --device /dev/bus/usb/ \
            $(yq .services.rosbot.image compose.yaml) \
            flash-firmware.py -p /dev/ttyUSBDB # todo
            # ros2 run rosbot_utils flash_firmware

        # docker run \
        #     --rm -it --privileged \
        #     --mount type=bind,source=/dev/ttyUSBDB,target=/dev/ttyUSBDB \
        #     $(yq .services.rosbot.image compose.yaml) \
        #     flash-firmware.py -p /dev/ttyUSBDB # todo
        #     # ros2 run rosbot_utils flash_firmware
    else
        echo "Please run \"just flash-firmware\" as non-root user"
    fi

# start containers on ROSbot XL
start-rosbot:
    #!/bin/bash
    docker compose up

# start containers on PC
start-pc:
    #!/bin/bash
    xhost +local:docker
    docker compose -f compose.pc.yaml up

# start the Gazebo simulation
start-gazebo:
    #!/bin/bash
    xhost +local:docker
    docker compose -f compose.sim.gazebo.yaml up

# run teleop_twist_keybaord (host)
run-teleop:
    #!/bin/bash
    . .env.local
    ros2 run teleop_twist_keyboard teleop_twist_keyboard

# run teleop_twist_keybaord (inside rviz2 container)
run-teleop-docker:
    #!/bin/bash
    docker compose -f compose.pc.yaml exec rviz /bin/bash -c "/ros_entrypoint.sh ros2 run teleop_twist_keyboard teleop_twist_keyboard"

# copy repo content to remote host with 'rsync' and watch for changes
sync hostname="${ROBOT_NAMESPACE}" password="husarion": _install-rsync
    #!/bin/bash
    if [ "$EUID" -ne 0 ]; then
        sshpass -p "husarion" rsync -vRr --delete ./ husarion@{{hostname}}:/home/husarion/${PWD##*/}
        while inotifywait -r -e modify,create,delete,move ./ ; do
            sshpass -p "{{password}}" rsync -vRr --delete ./ husarion@{{hostname}}:/home/husarion/${PWD##*/}
        done
    else
        echo "Please run \"just sync\" as non-root user"
    fi
