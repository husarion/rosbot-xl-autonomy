# rosbot-xl-autonomy

A step-by-step guide for the ROSbot XL to map an unknown environment and navigate autonomously within it from Rviz.

## Repository Setup

This repository contains the Docker Compose setup for both PC and ROSbot XL. You can clone it to both PC and ROSbot XL, or use the `./sync_with_rosbot.sh` script to clone it to your PC and keep it synchronized with the robot

```bash
git clone https://github.com/husarion/rosbot-xl-autonomy
cd rosbot-xl-autonomy 
export ROSBOT_ADDR=10.5.10.123 # Replace with your own ROSbot's IP or Husarnet hostname
./sync_with_rosbot.sh $ROSBOT_ADDR
```

## Flashing the ROSbot's Firmware

To flash the Micro-ROS based firmware for STM32F4 microcontroller responisble for low-level functionalities of ROSbot XL, execute in the ROSbot's shell:

```bash
docker stop rosbot-xl microros 2>/dev/null || true && \
docker run --rm -it --privileged \
--mount type=bind,source=/dev/ttyUSBDB,target=/dev/ttyUSBDB \
husarion/rosbot-xl:humble \
flash-firmware.py -p /dev/ttyUSBDB
```

## Choosing the Network (DDS) Config

Edit `net.env` file and uncomment on of the configs:

```bash
# =======================================
# Network config options (uncomment one)
# =======================================

# 1. Fast DDS + LAN
# RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# 2. Cyclone DDS + LAN
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# 3. Fast DDS + VPN
# RMW_IMPLEMENTATION=rmw_fastrtps_cpp
# FASTRTPS_DEFAULT_PROFILES_FILE=/husarnet-fastdds.xml

# 4. Cyclone DDS + VPN
# RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
# FASTRTPS_DEFAULT_PROFILES_FILE=/husarnet-fastdds.xml
# CYCLONEDDS_URI=file:///husarnet-cyclonedds.xml
```

> **VPN connection**
>
> If you choose to use the VPN option, both your ROSbot XL and laptop must be connected to the same Husarnet network.
> 
> If they are not, follow this guide:
> 
> [Connecting ROSbot and Laptop over the Internet (VPN)](https://husarion.com/software/os/remote-access/).

## Verifying Hardware Configuration

To ensure proper hardware configuration, review the content of the `.env` file and select the appropriate LIDAR baudrate and serial port. The hardware configuration is defined as follows:

```bash
# =======================================
# Hardware config
# =======================================
LIDAR_SERIAL=/dev/ttyUSB1

# for RPLIDAR A2M8 (red circle around the sensor):
# LIDAR_BAUDRATE=115200
# for RPLIDAR A2M12 and A3 (violet circle around the sensor):
LIDAR_BAUDRATE=256000
```

The default options should be suitable.

## I. Running on a Physical Robot

### ROSbot 2R

Pull the Docker images defined in `compose.yaml`:

```bash
docker compose pull
```

#### Option 1: SLAM Mode

To start a mapping mode

```bash
SLAM_MODE=slam docker compose up -d
```

#### Option 2: Localization Mode

To allow the ROSbot XL to localize on a previously created map using AMCL, run:

```bash
SLAM_MODE=localization docker compose up -d
```

> **Note:** You do not need to stop the containers to switch between modes.

### Stopping the Containers

```bash
docker compose down
```

### PC

To initiate a user interface and navigation stack based on Rviz, execute these commands on your PC:

```bash
xhost +local:docker && \
docker compose -f compose.pc.yaml up
```

To direct the robot to explore new areas autonomously and create a map (in the `slam` mode) or simply to position itself within an existing map, click on the **[2D Goal Pose]** button in rviz. It is important to note that when switching from `slam` to `localization` mode, you should use the **[2D Pose Estimate]** button in Rviz to inform the robot of its location on the map.

-----------

## II. Simulation

> **Prerequisites**
>
> The `compose.sim.gazebo.yaml` file uses NVIDIA Container Runtime. Make sure you have NVIDIA GPU and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed.

### Gazebo

Start the containers in a new terminal:

```bash
xhost +local:docker && \
SLAM_MODE=slam docker compose -f compose.sim.gazebo.yaml up
```

To direct the robot to explore new areas autonomously and create a map (in the `slam` mode) or simply to position itself within an existing map, click on the **[2D Goal Pose]** button in rviz. It is important to note that when switching from `slam` to `localization` mode, you should use the **[2D Pose Estimate]** button in Rviz to inform the robot of its location on the map.