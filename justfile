set dotenv-load

[private]
alias husarnet := connect-husarnet
[private]
alias flash := flash-firmware
[private]
alias rosbot := start-rosbot
[private]
alias gazebo := start-gazebo-sim
[private]
alias webots := start-webots-sim

[private]
default:
    @just --list --unsorted

[private]
pre-commit:
    #!/bin/bash
    if ! command -v pre-commit &> /dev/null; then
        pip install pre-commit
        pre-commit install
    fi
    pre-commit run -a

_install-rsync:
    #!/bin/bash
    if ! command -v rsync &> /dev/null || ! command -v sshpass &> /dev/null || ! command -v inotifywait &> /dev/null; then
        if [ "$EUID" -ne 0 ]; then
            echo -e "\e[1;33mPlease run as root to install dependencies\e[0m"
            exit 1
        fi
        sudo apt-get install -y rsync sshpass inotify-tools
    fi

_install-yq:
    #!/bin/bash
    if ! command -v /usr/bin/yq &> /dev/null; then
        if [ "$EUID" -ne 0 ]; then
            echo -e "\e[1;33mPlease run as root to install dependencies\e[0m"
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

# flash the proper firmware for STM32 microcontroller in ROSbot 2R / 2 PRO
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
    else
        echo "Please run \"just flash-firmware\" as non-root user"
    fi

# start ROSbot 2R / 2 PRO autonomy containers
start-rosbot:
    #!/bin/bash
    mkdir -m 775 -p maps
    docker compose down
    docker compose pull
    docker compose up

# start the Gazebo simulation
start-gazebo-sim:
    #!/bin/bash
    xhost +local:docker
    docker compose -f compose.sim.gazebo.yaml down
    docker compose -f compose.sim.gazebo.yaml pull
    docker compose -f compose.sim.gazebo.yaml up

# start the Webots simulation
start-webots-sim:
    #!/bin/bash
    xhost +local:docker
    docker compose -f compose.sim.webots.yaml down
    docker compose -f compose.sim.webots.yaml pull
    docker compose -f compose.sim.webots.yaml up

# Restart the Nav2 container
restart-navigation:
    #!/bin/bash
    docker compose down navigation
    docker compose up -d navigation

# Copy repo content to remote host with 'rsync' and watch for changes
sync hostname="${ROBOT_NAMESPACE}" password="husarion": _install-rsync
    #!/bin/bash
    mkdir -m 775 -p maps
    sshpass -p "{{password}}" rsync -vRr --exclude='.git/' --exclude='maps/' --delete ./ husarion@{{hostname}}:/home/husarion/${PWD##*/}
    while inotifywait -r -e modify,create,delete,move ./ --exclude='.git/' --exclude='maps/' ; do
        sshpass -p "{{password}}" rsync -vRr --exclude='.git/' --exclude='maps/' --delete ./ husarion@{{hostname}}:/home/husarion/${PWD##*/}
    done
