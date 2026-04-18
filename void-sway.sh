#!/bin/bash
set -e

echo "🚀 FINAL: GRUVBOX GNOME-STYLE SWAY (VOID NATIVE + HP TUNED + SURGICAL POLISH)"

# --------------------------------------------------
# 1. PACKAGES (NATIVE VOID + ADDONS)
# --------------------------------------------------
sudo xbps-install -Sy \
  sway swaybg swayidle swaylock \
  waybar \
  wofi wlogout \
  kitty \
  kanshi \
  brightnessctl \
  pipewire wireplumber pulseaudio-utils \
  mesa-dri vulkan-loader \
  dbus elogind NetworkManager network-manager-applet bind-utils \
  polkit-gnome \
  grim slurp wl-clipboard shotman \
  gtk+3 gtk+4 \
  gsettings-desktop-schemas \
  pavucontrol \
  font-awesome cantarell-fonts jetbrains-mono-nerd-font font-ubuntu \
  git libinput python3 \
  tlp tlp-rdw ncurses btrfs-progs \
  dunst udiskie

# Enable Core Services
sudo ln -sf /etc/sv/elogind /var/service/ || true
sudo ln -sf /etc/sv/dbus /var/service/ || true
sudo ln -sf /etc/sv/NetworkManager /var/service/ || true

# --------------------------------------------------
# 2. HARDWARE SERVICES (TLP)
# --------------------------------------------------
# We always enable TLP on the base system for your HP laptop battery/thermals.
# It will just remain dormant if run in a VM.
echo "💻 Enabling TLP for AMD power management..."
sudo ln -sf /etc/sv/tlp /var/service/ || true

# --------------------------------------------------
# 3. ENVIRONMENT (.bash_profile)
# --------------------------------------------------
cat << 'EOF' > ~/.bash_profile

export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland

# VM safe rendering (Void-native check)
if grep -qa "hypervisor" /proc/cpuinfo; then
  export WLR_RENDERER=pixman
  export WLR_NO_HARDWARE_CURSORS=1
fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
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
# 6. GTK & DUNST (THEMING)
# --------------------------------------------------
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/dunst

cat << 'EOF' > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-decoration-layout=appmenu:close
gtk-application-prefer-dark-theme=1
EOF

cat << 'EOF' > ~/.config/dunst/dunstrc
[global]
    font = Cantarell 10
    frame_color = "#504945"
    separator_color = "#504945"

[urgency_low]
    background = "#282828"
    foreground = "#ebdbb2"

[urgency_normal]
    background = "#282828"
    foreground = "#ebdbb2"

[urgency_critical]
    background = "#cc241d"
    foreground = "#fbf1c7"
EOF

# --------------------------------------------------
# 7. SWAY CONFIG (GRUVBOX + ADVANCED LAYOUT)
# --------------------------------------------------
mkdir -p ~/.config/sway

cat << 'EOF' > ~/.config/sway/config

input * xkb_layout us

set $mod Mod4
set $left h
set $down j
set $up k
set $right l

set $term kitty
set $menu wofi --show drun --allow-images --insensitive

# Window Colors (Gruvbox Dark)
client.focused          #458588   #458588    #ebdbb2  #458588   #458588
client.unfocused        #3c3836   #3c3836    #a89984  #3c3836   #3c3836
client.focused_inactive #504945   #504945    #a89984  #504945   #504945

# GNOME-like floating behavior
for_window [app_id=".*"] floating enable
focus_follows_mouse yes

# Workspace Behavior
workspace_auto_back_and_forth yes

# Startup Daemons
exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
exec_always waybar
exec_always kanshi
exec_always sh -c "pkill libinput-gestures; sleep 0.5; libinput-gestures-setup start"
exec_always nm-applet
exec_always /usr/libexec/polkit-gnome-authentication-agent-1 || true

exec dunst
exec udiskie

# Background (Gruvbox Base)
output * bg #282828 solid_color

# --- Keybindings ---
bindsym $mod+Return exec $term
bindsym $mod+q kill
bindsym --release Super_L exec $menu
bindsym $mod+Home exec wlogout

# Reload & Exit
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

# Screenshots
bindsym $mod+Shift+r exec shotman -c output
bindsym $mod+Shift+t exec shotman -c window
bindsym $mod+Shift+y exec shotman -c region

# Focus & Movement
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspaces
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

# Layouts & Toggles
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+a focus parent

# Scratchpad
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show

# Resize Mode
mode "resize" {
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px

    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px

    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# Window Appearance
default_floating_border pixel 0
default_border pixel 0
floating_modifier $mod normal
gaps inner 3
gaps outer 3
smart_gaps on
hide_edge_borders smart

# Hardware controls
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

# Idle / lock
exec_always swayidle -w \
 timeout 300 'swaylock -f -c 282828' \
 timeout 600 'swaymsg "output * dpms off"' \
 resume 'swaymsg "output * dpms on"' \
 before-sleep 'swaylock -f -c 282828'

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
# 9. WAYBAR (GRUVBOX STYLE WITH TRAY & NETWORK)
# --------------------------------------------------
mkdir -p ~/.config/waybar

cat << 'EOF' > ~/.config/waybar/config.jsonc
{
  "layer": "top",
  "position": "top",
  "height": 36,
  "margin": 0,

  "modules-left": ["custom/activities"],
  "modules-center": ["sway/workspaces"],
  "modules-right": ["network", "pulseaudio", "battery", "clock", "tray"],

  "custom/activities": {
    "format": "Activities",
    "on-click": "wofi --show drun --allow-images --insensitive",
    "tooltip": false
  },

  "sway/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{name}"
  },

  "clock": {
    "format": "󰅐  {:%H:%M}",
    "tooltip": false
  },

  "network": {
    "format-wifi": "󰖩  {essid}",
    "format-ethernet": "󰈀  Wired",
    "format-disconnected": "󰈂  Offline",
    "tooltip": false,
    "interval": 5,
    "on-click": "kitty -e nmtui"
  },

  "pulseaudio": {
    "format": "󰕾  {volume}%",
    "format-muted": "󰖁  Muted",
    "on-click": "pavucontrol",
    "scroll-step": 5,
    "tooltip": false
  },

  "battery": {
    "format": "󰁹  {capacity}%",
    "interval": 5,
    "states": {
        "warning": 20,
        "critical": 10
    },
    "tooltip": false
  },
  
  "tray": {
    "icon-size": 18,
    "spacing": 10
  }
}
EOF

cat << 'EOF' > ~/.config/waybar/style.css
* {
    border: none;
    border-radius: 0;
    min-height: 0;
    font-family: "Ubuntu", "JetBrainsMono Nerd Font", sans-serif;
    font-weight: 500;
    font-size: 14px;
    padding: 0;
}

window#waybar {
    background: #282828;
    border: 3px solid #282828;
    border-radius: 3px;
}

tooltip {
    background-color: #282828;
    border: 5px solid #282828;
    border-radius: 10px;
    color: #ebdbb2;
}

#custom-activities,
#clock,
#network,
#pulseaudio,
#battery,
#tray {
    margin: 7px 7px 7px 7px;
    padding: 2px 8px;
    background-color: #413d3a;
    border: 2px solid #413d3a;
    color: #c7ab7a;
    border-radius: 3px;
}

#custom-activities:hover {
    background-color: #504945;
}

#workspaces {
    background-color: #3f3836;
    padding: 0 7px;
    margin: 6px 0px 6px 6px;
    border: 2px solid #514947;
}

#workspaces button {
    all: initial;
    min-width: 20px;
    box-shadow: inset 0 -3px transparent;
    padding: 2px 4px;
    color: #ab9c88;
}

#workspaces button.focused {
    color: #ded8be;
}

#workspaces button.urgent {
    background-color: #e78a4e;
}

#battery.warning {
    color: #c7ab7a;
}

#battery.critical {
    color: #c14a4a;
}
EOF

# --------------------------------------------------
# 10. WOFI (GRUVBOX DARK STYLE)
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
  border: 2px solid #413d3a;
  background-color: #282828;
  border-radius: 3px;
  font-family: "Ubuntu", sans-serif;
  font-size: 16px;
}

#input {
  margin: 20px;
  padding: 10px;
  border: 2px solid #504945;
  border-radius: 3px;
  background-color: #3c3836;
  color: #ebdbb2;
}

#inner-box { margin: 10px; }
#outer-box { margin: 10px; padding: 10px; }
#scroll { margin: 10px; }
#text { margin: 5px; color: #ebdbb2; }

#entry {
  padding: 8px;
  border-radius: 3px;
}

#entry:selected {
  background-color: #458588;
  color: #282828;
}
EOF

# --------------------------------------------------
# DONE
# --------------------------------------------------
echo ""
echo "✅ FINAL GRUVBOX SWAY READY"
echo "👉 Reboot to finalize input group and system changes."
echo "👉 Tap SUPER to launch apps."
echo "👉 Super+R enters resize mode (Esc/Enter to exit)."
echo "👉 Swipe up (3 fingers) for overview."
