# ROS2 development container for robotsix-mill-ros2 workspace.
# Override ROS_DISTRO to pin a specific release:  docker build --build-arg ROS_DISTRO=jazzy .
ARG ROS_DISTRO=rolling

FROM ros:$ROS_DISTRO-ros-base

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Re-create user if it exists (e.g. Ubuntu Noble ships 'ubuntu')
RUN if id -u $USER_UID ; then userdel "$(id -un $USER_UID)" ; fi

# hadolint ignore=DL3008
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y --no-install-recommends sudo \
    && rm -rf /var/lib/apt/lists/* \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# hadolint ignore=DL3008
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        python3-pip \
        python3-colcon-common-extensions \
        build-essential \
        cmake \
        git \
        ccache \
    && rm -rf /var/lib/apt/lists/*

# Set up ccache to wrap compilers (symlink-based interception)
ENV PATH=/usr/lib/ccache:$PATH
ENV CCACHE_DIR=/home/$USERNAME/.ccache
ENV CCACHE_MAXSIZE=10G

RUN pip install --no-cache-dir vcs2l==1.1.7

ENV SHELL=/bin/bash

# Source the ROS setup in every new shell
RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/$USERNAME/.bashrc

USER $USERNAME
CMD ["/bin/bash"]
