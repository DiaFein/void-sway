#!/bin/bash
set -e

echo "🚀 STABLE GNOME-LIKE SWAY SETUP (ULTIMATE EDITION)"

# --------------------------------------------------
# 1. PACKAGES (STABLE + ELOGIND + NERD FONTS)
# --------------------------------------------------
sudo xbps-install -Sy \
  sway swaybg swayidle swaylock \
  Waybar \
  wofi \
  kitty \
  kanshi \
  brightnessctl \
  pulseaudio-utils \
  mesa-dri vulkan-loader \
  dbus elogind \
  polkit-gnome \
  grim slurp wl-clipboard \
  gtk3 gtk4 \
  gsettings-desktop-schemas \
  pavucontrol \
  font-awesome cantarell-fonts nerd-fonts \
  nwg-dock \
  nwg-menu \
  git libinput python3

# Enable Services (Strictly Elogind for session management)
sudo ln -sf /etc/sv/elogind /var/service/ || true
sudo ln -sf /etc/sv/dbus /var/service/ || true

# --------------------------------------------------
# 2. INSTALL GESTURES & PERMISSIONS
# --------------------------------------------------
cd /tmp
rm -rf libinput-gestures
git clone https://github.com/bulletmark/libinput-gestures.git
cd libinput-gestures
sudo ./libinput-gestures-setup install

# Add user to input group for gesture support
sudo gpasswd -a $USER input

# --------------------------------------------------
# 3. ENVIRONMENT
# --------------------------------------------------
cat << 'EOF' > ~/.bash_profile

export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland

# VM safe rendering
if systemd-detect-virt | grep -q "vm"; then
  export WLR_RENDERER=pixman
  export WLR_NO_HARDWARE_CURSORS=1
fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec dbus-run-session sway
fi
EOF

# --------------------------------------------------
# 4. GTK (GNOME STYLE)
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
# 5. SWAY CONFIG
# --------------------------------------------------
mkdir -p ~/.config/sway

cat << 'EOF' > ~/.config/sway/config

set $mod Mod4
set $term kitty
set $menu wofi --show drun --width 50% --height 50%

# GNOME-like floating
for_window [app_id=".*"] floating enable
focus_follows_mouse yes

# Startup
exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
exec_always waybar
exec_always nwg-dock
exec_always kanshi
exec_always libinput-gestures-setup start
exec_always /usr/libexec/polkit-gnome-authentication-agent-1 || true

# Idle & Lock (GNOME Behavior with Nord aesthetic)
exec_always swayidle -w \
  timeout 300 'swaylock -f -c 2e3440' \
  timeout 600 'swaymsg "output * dpms off"' \
  resume 'swaymsg "output * dpms on"' \
  before-sleep 'swaylock -f -c 2e3440'

# Background (Nord)
output * bg #2e3440 solid_color

# Keybinds
bindsym $mod Return exec $term
bindsym $mod d exec $menu
bindsym $mod q kill
bindsym $mod f fullscreen
bindsym $mod Tab exec nwg-menu

# Hardware Controls
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

floating_modifier $mod normal
EOF

# --------------------------------------------------
# 6. GESTURE CONFIG
# --------------------------------------------------
mkdir -p ~/.config

cat << 'EOF' > ~/.config/libinput-gestures.conf

gesture swipe left 3 swaymsg workspace next
gesture swipe right 3 swaymsg workspace prev
gesture swipe up 3 exec wofi --show drun

EOF

# --------------------------------------------------
# 7. WAYBAR (TRUE GNOME STYLE)
# --------------------------------------------------
mkdir -p ~/.config/waybar

cat << 'EOF' > ~/.config/waybar/config.jsonc
{
  "layer": "top",
  "position": "top",
  "height": 36,
  "margin": 0,

  "modules-left": ["custom/activities", "sway/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "battery", "tray"],

  "custom/activities": {
    "format": "Activities",
    "on-click": "nwg-menu",
    "tooltip": false
  },

  "sway/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{icon}",
    "format-icons": {
      "1": "●",
      "2": "●",
      "3": "●",
      "4": "●",
      "5": "●"
    }
  },

  "clock": {
    "format": "{:%a %b %d  %H:%M}",
    "tooltip": false
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
  min-height: 0;
}

window#waybar {
  background: rgba(46, 52, 64, 0.95);
  color: #eceff4;
}

/* LEFT: Activities & Workspaces */
#custom-activities {
  padding: 0 14px;
  margin-left: 6px;
  font-weight: 600;
}

#custom-activities:hover {
  background: rgba(255, 255, 255, 0.08);
  border-radius: 6px;
}

#workspaces {
  margin-left: 10px;
}

#workspaces button {
  padding: 0 4px;
  color: #81a1c1; /* Dimmed Nord Blue for inactive */
  background: transparent;
  box-shadow: none;
}

#workspaces button:hover {
  background: transparent;
  color: #88c0d0;
}

#workspaces button.focused {
  color: #eceff4; /* Bright white for active dot */
}

#workspaces button.urgent {
  color: #bf616a;
}

/* CENTER: Clock */
#clock {
  font-weight: 600;
  font-size: 14px;
  padding: 0 20px;
}

/* RIGHT MODULES */
#pulseaudio,
#battery,
#tray {
  padding: 0 10px;
}

/* Hover effect like GNOME */
#pulseaudio:hover,
#battery:hover,
#tray:hover {
  background: rgba(255, 255, 255, 0.08);
  border-radius: 6px;
}

/* Tray spacing */
#tray {
  margin-right: 8px;
}
EOF

# --------------------------------------------------
# 8. WOFI
# --------------------------------------------------
mkdir -p ~/.config/wofi

cat << 'EOF' > ~/.config/wofi/style.css
window {
  background-color: #2e3440;
  border-radius: 12px;
}
EOF

# --------------------------------------------------
# DONE
# --------------------------------------------------
echo ""
echo "✅ ULTIMATE GNOME-LIKE SWAY READY"
echo "👉 Reboot to apply input group changes"
echo "👉 SUPER+TAB = Overview"
