# rosbot-xl-autonomy

Autonomous navigation & mapping for ROSbot XL with RViz interface running on remote PC. Works over the Internet thanks to Husarnet VPN

> [!NOTE]
> There are two setups on two separate branchers available
> | branch name | description |
> | - | - |
> | [**ros2router**](https://github.com/husarion/rosbot-xl-autonomy/tree/ros2router) | Running ROS 2 containers on ROSbot and on PC with the interface in RViz |
> | [**foxglove**](https://github.com/husarion/rosbot-xl-autonomy/tree/foxglove) | Running ROS 2 containers only on ROSbot with a web user interface powered by Foxglove |

![RViz ROSbot UI](.docs/rviz.png)

## 🛍️ Necessary Hardware

For the execution of this project, the following components are required:

1. **[ROSbot XL](https://husarion.com/manuals/rosbot-xl/)** - with any SBC (RPi4, NUC or Jetson)
2. **[SLAMTEC lidars](https://husarion.com/tutorials/ros-equipment/oak-1-lite/)** - A2, A3, S2 or S3 models

These items are available for purchase as a complete kit at [our online store](https://store.husarion.com/collections/robots/products/rosbot-xl).

## Quick start (Physical ROSbot)

> [!NOTE]
> To simplify the execution of this project, we are utilizing [just](https://github.com/casey/just).
>
> Install it with:
>
> ```bash
> curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/bin
> ```

To see all available commands just run `just`:

```bash
husarion@rosbotxl:~/rosbot-xl-autonomy$ just
Available recipes:
    connect-husarnet joincode hostname # connect to Husarnet VPN network
    sync hostname="${ROBOT_NAMESPACE}" password="husarion" # Copy repo content to remote host with 'rsync' and watch for changes
    flash-firmware     # flash the proper firmware for STM32 microcontroller in ROSbot XL
    start-rosbot       # start containers on a physical ROSbot XL
    start-pc           # start containers on PC
    start-simulation engine="gazebo" # start the simulation (available options: gazebo, webots)
    run-teleop         # run teleop_twist_keybaord (host)
    run-teleop-docker  # run teleop_twist_keybaord (inside rviz2 container)
    restart-navigation # Restart the Nav2 container
```

### 🌎 Step 1: Connecting ROSbot and Laptop over VPN

Ensure that both ROSbot XL and your laptop are linked to the same Husarnet VPN network. If they are not follow these steps:

1. Setup a free account at [app.husarnet.com](https://app.husarnet.com/), create a new Husarnet network, click the **[Add element]** button and copy the code from the **Join Code** tab.
2. Run in the linux terminal on your PC:
   ```bash
   cd rosbot-xl-authonomy/ # remember to run all "just" commands in the repo root folder
   export JOINCODE=<PASTE_YOUR_JOIN_CODE_HERE>
   just connect-husarnet $JOINCODE my-laptop
   ```
3. Run in the linux terminal of your ROSbot:
   ```bash
   export JOINCODE=<PASTE_YOUR_JOIN_CODE_HERE>
   sudo husarnet join $JOINCODE rosbotxl
   ```
   > [!IMPORTANT]
   > note that `rosbotxl` is a default ROSbot hostname used in this project. If you want to change it, edit the `.env` file and change the line:
   > ```bash
   > ROBOT_NAMESPACE=rosbotxl
   > ```

### 📡 Step 2: Sync

Copy the local changes (on PC) to the remote ROSbot

```bash
just sync rosbotxl # or a different ROSbot hostname you used in Step 1 p.3
```

> [!NOTE]
> This `just sync` script locks the terminal and synchronizes online all changes made locally on the robot. `rosbotxl` is the name of device set in Husarnet.

### 🔧 Step 3: Verifying User Configuration

To ensure proper user configuration, review the content of the `.env` file and select the appropriate configuration (the default options should be suitable).

- **`LIDAR_BAUDRATE`** - depend on mounted LiDAR,
- **`MECANUM`** - wheel type,
- **`SLAM`** - choose between mapping and localization modes,
- **`SAVE_MAP_PERIOD`** - period of time for autosave map (set `0` to disable),
- **`CONTROLLER`** - choose the navigation controller type,
- **`ROBOT_NAMESPACE`** - type your ROSbot device name the same as in Husarnet.

> [!IMPORTANT]
> The value of the `ROBOT_NAMESPACE` parameter in the `.env` file should be the same as the Husarnet hostname for ROSbot XL.

### 🤖 Step 4: Running Navigation & Mapping

#### ROSbot

1. Connect to the ROSbot.

   ```bash
   ssh husarion@rosbotxl
   cd rosbot-xl-autonomy
   ```

   > [!NOTE]
   > `rosbotxl` is the name of device set in Husarnet.

2. Flashing the ROSbot's Firmware.

   To flash the Micro-ROS based firmware for STM32F4 microcontroller responsible for low-level functionalities of ROSbot XL, execute in the ROSbot's shell:

   ```bash
   just flash-firmware
   # or just flash
   ```

3. Running autonomy on ROSbot.

   ```bash
   just start-rosbot
   # or just rosbot
   ```

#### PC

To initiate RViz user interface, execute below command on your PC:

```bash
just start-pc
# or just pc
```

### 🚗 Step 5: Control the ROSbot from RViz

To instruct the robot to autonomously explore new areas and create a map (in `slam` mode) use the **[2D Goal Pose]** button in RViz. When `SLAM` is off, you can indicate the robot's current position by **[2D Pose Estimate]** button.

![RViz ROSbot UI](.docs/rviz.png)

------

## Simulation

> [!IMPORTANT]
> To run `Gazebo` or `Webots` Simulators you have to use computer with NVIDIA GPU and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed.

If you don't have a physical ROSbot XL you can run this project in a simulation.

### Gazebo

To start Gazebo simulator run:

```bash
just start-simulation "gazebo"
# or just gazebo
```

### Webots

To start Webots simulator run:

```bash
just start-simulation "webots"
# or just webots
```
