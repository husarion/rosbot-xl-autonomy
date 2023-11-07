# rosbot-xl-autonomy

A step-by-step guide for the ROSbot XL to map an unknown environment and navigate autonomously within it from RViz.

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
husarion/rosbot-xl:humble-0.8.2-20230712 \
flash-firmware.py -p /dev/ttyUSBDB
```

## Verifying User Configuration

To ensure proper user configuration, review the content of the `.env` file and select the appropriate configuration (the default options should be suitable).

### Parameters

- **`LIDAR_BAUDRATE`** - depend on mounted LiDAR
- **`MECANUM`** - wheel type
- **`SLAM`** - choose between mapping and localization modes
- **`CONTROLLER`** - choose controller type

## Choosing the Network (DDS) Config

Edit `net.env` file and uncomment on of the configs:

### Parameters

- **`RMW_IMPLEMENTATION`**
- **`ROS_DOMAIN_ID`**

> [!NOTE]
> If you choose to use the VPN option, both your ROSbot XL and laptop must be connected to the same Husarnet network. If they are not, follow this guide: [Connecting ROSbot and Laptop over the Internet (VPN)](https://husarion.com/software/os/remote-access/).

## I. Running on a Physical Robot

### ROSbot XL

Pull and run Docker images defined in `compose.yaml`:

```bash
docker compose pull
docker compose up -d
```

> [!NOTE]
> You need to restart containers to switch between modes. Use following command to stop container: `docker compose down`.

### PC

To initiate a user interface and navigation stack based on RViz, execute these commands on your PC:

```bash
xhost +local:docker && \
docker compose -f compose.pc.yaml up
```

To direct the robot to explore new areas autonomously and create a map (in the `slam` mode) or simply to position itself within an existing map, click on the **[2D Goal Pose]** button in RViz. It is important to note that when switching from `slam` to `localization` mode, you should use the **[2D Pose Estimate]** button in RViz to inform the robot of its location on the map.

---

## II. Simulation

> [!IMPORTANT]
> The `compose.sim.gazebo.yaml` and `compose.sim.webots.yaml` files use NVIDIA Container Runtime. Make sure you have NVIDIA GPU and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed.

### Gazebo

Start the containers in a new terminal:

```bash
xhost +local:docker && \
docker compose -f compose.sim.gazebo.yaml up
```

### Webots

Start the containers in a new terminal:

```bash
xhost +local:docker && \
docker compose -f compose.sim.webots.yaml up
```

To direct the robot to explore new areas autonomously and create a map (in the `slam` mode) or simply to position itself within an existing map, click on the **[2D Goal Pose]** button in RViz. It is important to note that when switching from `slam` to `localization` mode, you should use the **[2D Pose Estimate]** button in RViz to inform the robot of its location on the map.
