#!/bin/bash
set -e

echo "🚀 FINAL: STABLE GNOME-LIKE SWAY (VOID NATIVE + NETWORK + HP TUNED)"

# --------------------------------------------------
# 1. PACKAGES (NATIVE VOID + STABILITY + NETWORK)
# --------------------------------------------------
sudo xbps-install -Sy \
  sway swaybg swayidle swaylock \
  waybar \
  wofi \
  kitty \
  kanshi \
  brightnessctl \
  pulseaudio-utils \
  mesa-dri vulkan-loader \
  dbus elogind NetworkManager \
  polkit-gnome \
  grim slurp wl-clipboard \
  gtk3 gtk4 \
  gsettings-desktop-schemas \
  pavucontrol \
  font-awesome cantarell-fonts jetbrains-mono-nerd-font \
  git libinput python3 \
  tlp tlp-rdw ncurses btrfs-progs

# Enable Core Services
sudo ln -sf /etc/sv/elogind /var/service/ || true
sudo ln -sf /etc/sv/dbus /var/service/ || true
sudo ln -sf /etc/sv/NetworkManager /var/service/ || true

# --------------------------------------------------
# 2. VM DETECTION & HARDWARE SERVICES
# --------------------------------------------------
if systemd-detect-virt | grep -q "vm"; then
  VM_MODE=1
  echo "🖥️ VM Mode Detected: Skipping hardware power services..."
else
  VM_MODE=0
  echo "💻 Hardware Mode Detected: Enabling TLP for AMD power management..."
  sudo ln -sf /etc/sv/tlp /var/service/ || true
fi

# --------------------------------------------------
# 3. ENVIRONMENT (.bash_profile)
# --------------------------------------------------
cat << EOF > ~/.bash_profile

export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland

if [ "$VM_MODE" = "1" ]; then
  export WLR_RENDERER=pixman
  export WLR_NO_HARDWARE_CURSORS=1
fi

if [ -z "\$DISPLAY" ] && [ "\$XDG_VTNR" -eq 1 ]; then
  exec dbus-run-session sway
fi
EOF

# --------------------------------------------------
# 4. INSTALL GESTURES
# --------------------------------------------------
cd /tmp
rm -rf libinput-gestures
git clone https://github.com/bulletmark/libinput-gestures.git
cd libinput-gestures
sudo ./libinput-gestures-setup install

# Add user to input group for touchpad control
sudo gpasswd -a $USER input

# --------------------------------------------------
# 5. KANSHI (DISPLAY PROFILE)
# --------------------------------------------------
mkdir -p ~/.config/kanshi

cat << 'EOF' > ~/.config/kanshi/config
profile default {
  output * enable
}
EOF

# --------------------------------------------------
# 6. GTK (GNOME STYLE)
# --------------------------------------------------
mkdir -p ~/.config/gtk-3.0

cat << 'EOF' > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-decoration-layout=appmenu:close
gtk-application-prefer-dark-theme=1
EOF

# --------------------------------------------------
# 7. SWAY CONFIG (GNOME-LIKE UX)
# --------------------------------------------------
mkdir -p ~/.config/sway

cat << 'EOF' > ~/.config/sway/config

set $mod Mod4
set $term kitty
set $menu wofi --show drun --allow-images --insensitive

# GNOME-like floating behavior
for_window [app_id=".*"] floating enable
focus_follows_mouse yes

# Startup
exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
exec_always waybar
exec_always kanshi
exec_always pkill libinput-gestures; libinput-gestures-setup start
exec_always /usr/libexec/polkit-gnome-authentication-agent-1 || true

# Background (Nord)
output * bg #2e3440 solid_color

# Keybindings
bindsym $mod+space exec $menu
bindsym $mod+d exec $menu
bindsym $mod+Return exec $term
bindsym $mod+q kill
bindsym $mod+f fullscreen

# Overview (GNOME-like)
bindsym $mod+Tab exec $menu

# Workspace navigation
bindsym $mod+Left workspace prev
bindsym $mod+Right workspace next

# Window switcher
bindsym Alt+Tab exec wofi --show window --allow-images --insensitive

# Hardware controls
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

# Idle / lock (GNOME-like behavior)
exec_always swayidle -w \
 timeout 300 'swaylock -f -c 2e3440' \
 timeout 600 'swaymsg "output * dpms off"' \
 resume 'swaymsg "output * dpms on"' \
 before-sleep 'swaylock -f -c 2e3440'

floating_modifier $mod normal

EOF

# --------------------------------------------------
# 8. GESTURES CONFIG
# --------------------------------------------------
mkdir -p ~/.config

cat << 'EOF' > ~/.config/libinput-gestures.conf

gesture swipe left 3 swaymsg workspace next
gesture swipe right 3 swaymsg workspace prev
gesture swipe up 3 exec wofi --show drun --allow-images --insensitive

EOF

# --------------------------------------------------
# 9. WAYBAR (GNOME TOP BAR WITH NETWORK)
# --------------------------------------------------
mkdir -p ~/.config/waybar

cat << 'EOF' > ~/.config/waybar/config.jsonc
{
  "layer": "top",
  "position": "top",
  "height": 36,
  "margin": 0,

  "modules-left": ["custom/activities"],
  "modules-center": ["clock"],
  "modules-right": ["network", "pulseaudio", "battery", "tray"],

  "custom/activities": {
    "format": "Activities",
    "on-click": "wofi --show drun --allow-images --insensitive",
    "tooltip": false
  },

  "clock": {
    "format": "{:%H:%M}",
    "tooltip": false
  },

  "network": {
    "format-wifi": "  {essid}",
    "format-ethernet": "󰈀  Wired",
    "format-disconnected": "󰖪  Offline",
    "tooltip-format": "{ifname} via {gwaddr}\n󰇚 {bandwidthDownBytes}  󰕒 {bandwidthUpBytes}",
    "on-click": "kitty -e nmtui"
  },

  "pulseaudio": {
    "format": "  {volume}%",
    "format-muted": "  Muted",
    "on-click": "pavucontrol",
    "tooltip": false
  },

  "battery": {
    "format": "󰁹 {capacity}%",
    "tooltip": false
  }
}
EOF

cat << 'EOF' > ~/.config/waybar/style.css
* {
  border: none;
  border-radius: 0;
  font-family: "Cantarell", "JetBrainsMono Nerd Font", sans-serif;
  font-size: 14px;
  font-weight: 500;
}

window#waybar {
  background: rgba(46, 52, 64, 0.95);
  color: #eceff4;
}

#custom-activities {
  padding: 0 14px;
  margin-left: 6px;
  font-weight: 600;
}

#custom-activities:hover {
  background: rgba(255,255,255,0.08);
  border-radius: 6px;
}

#clock {
  font-weight: 600;
  padding: 0 20px;
}

#network,
#pulseaudio,
#battery,
#tray {
  padding: 0 10px;
}

#network:hover,
#pulseaudio:hover,
#battery:hover,
#tray:hover {
  background: rgba(255,255,255,0.08);
  border-radius: 6px;
}

#tray {
  margin-right: 8px;
}
EOF

# --------------------------------------------------
# 10. WOFI (GNOME APP GRID STYLE)
# --------------------------------------------------
mkdir -p ~/.config/wofi

cat << 'EOF' > ~/.config/wofi/config
show=drun
width=50%
height=60%
prompt=Search apps...
insensitive=true
allow_images=true
EOF

cat << 'EOF' > ~/.config/wofi/style.css
window {
  margin: 0px;
  border: 2px solid #3b4252;
  background-color: rgba(46, 52, 64, 0.95);
  border-radius: 15px;
  font-family: "Cantarell", sans-serif;
  font-size: 16px;
}

#input {
  margin: 20px;
  padding: 10px;
  border: none;
  border-radius: 10px;
  background-color: #3b4252;
  color: #eceff4;
}

#inner-box {
  margin: 10px;
}

#outer-box {
  margin: 10px;
  padding: 10px;
}

#scroll {
  margin: 10px;
}

#text {
  margin: 5px;
  color: #eceff4;
}

#entry {
  padding: 8px;
  border-radius: 8px;
}

#entry:selected {
  background-color: #4c566a;
}
EOF

# --------------------------------------------------
# DONE
# --------------------------------------------------
echo ""
echo "✅ FINAL GNOME-LIKE SWAY READY"
echo "👉 Reboot to finalize input group and network changes"
echo "👉 Click 'Activities' or press SUPER+SPACE to launch apps"
echo "👉 Click the Network icon in the top right to manage Wi-Fi"
echo "👉 Swipe up (3 fingers) for overview"
