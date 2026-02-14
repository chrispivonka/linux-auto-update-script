# To Test Locally via Docker:=
#   1. Build the image: docker build -t auto-updater .
#   2. Run with a restart policy and volume mount:
#      docker run -it --name update-test \
#        --restart always \
#        -v $(pwd):/home/testuser/GitHub/linux-auto-update-script \
#        auto-updater
#      Use code with caution.
#
#   3. Simulate a Reboot Requirement: While the container is running (or before you start it), manually create the reboot file inside the container to see the cycle trigger: sudo touch /var/run/reboot-required.

FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    sudo curl git build-essential procps && \
    rm -rf /var/lib/apt/lists/*

# Create test user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
ENV USER=testuser
WORKDIR /home/testuser

# Install Homebrew
RUN /bin/bash -c "$(curl --max-time 300 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || /bin/bash -c "$(curl --max-time 300 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

# Setup repo structure
RUN mkdir -p /home/testuser/GitHub/linux-auto-update-script

# Set the bootstrap script as the entry point
# This mimics the @reboot behavior in a Docker environment
ENTRYPOINT ["/bin/bash", "/home/testuser/GitHub/linux-auto-update-script/bootstrap_updates.sh"]
