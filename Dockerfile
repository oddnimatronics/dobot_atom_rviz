ARG ROS_DISTRO=humble
FROM ros:${ROS_DISTRO}-ros-base

ARG ROS_DISTRO=humble
SHELL ["/bin/bash", "-c"]

ENV ROS_DISTRO=${ROS_DISTRO}
WORKDIR /ros2_ws

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-colcon-common-extensions \
        ros-${ROS_DISTRO}-joint-state-publisher-gui \
        ros-${ROS_DISTRO}-robot-state-publisher \
        ros-${ROS_DISTRO}-rviz2 \
        ros-${ROS_DISTRO}-xacro && \
    rm -rf /var/lib/apt/lists/*

ENV QT_X11_NO_MITSHM=1
ENV LIBGL_ALWAYS_SOFTWARE=1

COPY . /ros2_ws/src/dobot_atom_description

RUN source /opt/ros/${ROS_DISTRO}/setup.bash && \
    colcon build --packages-up-to dobot_atom_description --symlink-install

CMD ["bash"]
