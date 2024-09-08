#!/bin/bash

# Update and Upgrade System
echo "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y
echo "Update and upgrade completed."

# Setup System - Part 1
echo "Setting timezone to Europe/Berlin..."
sudo timedatectl set-timezone Europe/Berlin

echo "Expanding filesystem..."
sudo raspi-config --expand-rootfs

# Static IP Setup
if ! systemctl is-enabled systemd-networkd; then
    echo "Enabling and starting systemd-networkd..."
    sudo systemctl enable systemd-networkd
    sudo systemctl start systemd-networkd
fi

if ! systemctl is-enabled systemd-resolved; then
    echo "Installing, enabling, and starting systemd-resolved..."
    sudo apt install systemd-resolved -y
    sudo systemctl enable systemd-resolved
    sudo systemctl start systemd-resolved
fi

echo "Setting static IP..."
cat <<EOT | sudo tee /etc/systemd/network/10-static-network.network > /dev/null
[Match]
Name=wlan0

[Network]
Address=192.168.1.100/24  # Your static IP
Gateway=192.168.1.1       # Your router's IP
DNS=192.168.1.1           # Your DNS server (or Google's DNS: 8.8.8.8)
EOT

sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Custom SSH Login Message
echo "Creating custom SSH login banner..."
cat <<'EOT' | sudo tee /etc/ssh/sshd_banner > /dev/null
  _____  _____ _____ ___
 |  __ \|  __ \_   _/ _ \
 | |__) | |__) || || | | |
 |  _  /|  ___/ | || | | |
 | | \ \| |    _| || |_| |
 |_|  \_\_|   |_____\___/
EOT

sudo sed -i 's|#Banner none|Banner /etc/ssh/sshd_banner|' /etc/ssh/sshd_config

# Overclock Settings
echo "Configuring overclocking..."
sudo sed -i '$a [all]\narm_freq=1085\ngpu_freq=530\nover_voltage=2\ncore_freq=515\nsdram_freq=533\nover_voltage_sdram=1' /boot/firmware/config.txt

# Reboot to apply changes
echo "Rebooting system..."
sudo reboot

# Add "Continue Script after reboot function"

# --- After Reboot, Part 2 ---
# This part would be executed manually after reboot or as part of another script.

# SSH with new IP
# ssh user@192.168.1.100

# Create directory structure
echo "Creating directories..."
mkdir -p ~/Services/Portainer ~/Services/Samba ~/Services/PiHole ~/Services/Bitwarden ~/Services/Homer
mkdir -p ~/Services/PiHole/data ~/Services/Bitwarden/data ~/Services/Homer/data
mkdir ~/Storage ~/Downloads

# Install Docker
echo "Installing Docker..."
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER
sudo systemctl start docker
sudo systemctl enable docker

echo "Please log out and log back in to use Docker."

# After re-login, set up services
# Portainer
if [[ $(uname -m) == "aarch64" ]]; then
    echo "Setting up Portainer..."
    # Add your docker-compose.yml file for Portainer
    docker compose up -d
fi

# Samba
echo "Setting up Samba..."
# Add your docker-compose.yml file for Samba
docker compose up -d

# Homer Dashboard
echo "Setting up Homer dashboard..."
# Add your docker-compose.yml file for Homer
docker compose up -d
echo "Homer dashboard accessible at <ip>:8000"

# PiHole
echo "Setting up PiHole..."
# Add your docker-compose.yml file for PiHole
docker compose up -d

echo "Setup complete."
