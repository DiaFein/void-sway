#!/bin/bash

# Ensure script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit
fi

echo "Updating system and installing Sway environment..."

# 1. Update XBPS and install packages
# Note: Ubuntu 'fonts-' packages are mapped to Void '*-fonts-ttf' equivalents
xbps-install -Sy sway swaybg swaylock swayidle xdg-desktop-portal-wlr \
    waybar wofi foot noto-fonts-emoji noto-fonts-ttf dejavu-fonts-ttf \
    font-awesome6 pavucontrol grim slurp wl-clipboard xdg-user-dirs \
    nautilus mousepad firefox dbus elogind

# 2. Enable necessary services for Wayland/Sway
echo "Enabling services (D-Bus and Elogind)..."
ln -sf /etc/sv/dbus /var/service/
ln -sf /etc/sv/elogind /var/service/

# 3. Create standard user directories
# We run this as the actual user who invoked sudo
echo "Initializing user directories..."
sudo -u "$SUDO_USER" xdg-user-dirs-update

# 4. Refresh font cache
echo "Refreshing font cache..."
fc-cache -fv

# 5. Optional: Create initial Sway config if it doesn't exist
USER_HOME=$(eval echo "~$SUDO_USER")
if [ ! -f "$USER_HOME/.config/sway/config" ]; then
    echo "Creating default Sway configuration..."
    sudo -u "$SUDO_USER" mkdir -p "$USER_HOME/.config/sway"
    sudo -u "$SUDO_USER" cp /etc/sway/config "$USER_HOME/.config/sway/config"
fi

echo "-------------------------------------------------------"
echo "Setup Complete! Please REBOOT to ensure services start."
echo "You can start Sway by typing 'sway' after logging in."
echo "-------------------------------------------------------"
