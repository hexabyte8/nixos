# Tablet mode configuration for Framework 12 (2-in-1 laptop)
# Features:
#   - On-Screen Keyboard (wvkbd) with touch gestures (hyprgrass)
#   - Display rotation toggle for tablet mode
#
# Toggle methods for OSK:
#   1. Keybind: SUPER + ` (backtick/grave key - toggle OSK)
#   2. Swipe: From bottom edge upward (via hyprgrass plugin)
#
# Display rotation:
#   1. Keybind: SUPER + F7 (toggle display rotation 180°)
#
# wvkbd uses SIGRTMIN (signal 34) to toggle visibility
# Reference: https://github.com/jjsullivan5196/wvkbd

{ config, lib, pkgs, host, ... }:

let
  # Only enable for tiramisu (Framework 12 laptop with tablet mode)
  isTabletHost = host == "tiramisu";
  
  # Toggle script for wvkbd - sends SIGRTMIN (34) to toggle visibility
  # This is more robust than the raw kill command as it also handles restart
  toggleOskScript = pkgs.writeShellScriptBin "toggle-osk" ''
    #!/usr/bin/env bash
    # Toggle wvkbd-mobintl visibility by sending SIGRTMIN (signal 34)
    # If wvkbd is not running, start it
    
    if pgrep -x "wvkbd-mobintl" > /dev/null; then
      # wvkbd is running, toggle visibility with signal RTMIN (34)
      # Using pkill for safer signal delivery to all matching processes
      pkill -x wvkbd-mobintl --signal RTMIN
    else
      # wvkbd not running, start it (hidden initially with -H flag)
      wvkbd-mobintl -H &
    fi
  '';

  # Toggle display rotation script for 2-in-1 tablet mode
  # Flips the primary display 180° (normal <-> inverted)
  toggleRotateScript = pkgs.writeShellScriptBin "toggle-rotate" ''
    #!/usr/bin/env bash
    # Toggle display rotation between normal (0) and inverted (180°)
    # Uses hyprctl to get current transform and toggle it
    
    # Get the focused monitor name
    MONITOR=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')
    
    if [ -z "$MONITOR" ]; then
      echo "No focused monitor found"
      exit 1
    fi
    
    # Get current transform value (0 = normal, 2 = 180°)
    CURRENT_TRANSFORM=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r ".[] | select(.name == \"$MONITOR\") | .transform")
    
    if [ "$CURRENT_TRANSFORM" = "2" ]; then
      # Currently rotated 180°, set back to normal
      hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,0"
      notify-send "Display" "Rotation: Normal" -t 2000
    else
      # Currently normal (or other), rotate 180°
      hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,2"
      notify-send "Display" "Rotation: Inverted (180°)" -t 2000
    fi
  '';

in
lib.mkIf isTabletHost {
  # Add wvkbd, toggle scripts to user packages
  home.packages = with pkgs; [
    wvkbd           # Virtual keyboard for Wayland (wvkbd-mobintl variant)
    toggleOskScript
    toggleRotateScript
  ];

  # Seed Hyprland config snippets for tablet mode (OSK + display rotation)
  # These will be appended to the user's hyprland.conf via activation script
  home.activation.seedTabletConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    
    # Create tablet mode config snippet for Hyprland
    TABLET_CONF="$HOME/.config/hypr/tablet.conf"
    mkdir -p "$HOME/.config/hypr"
    
    cat > "$TABLET_CONF" << 'EOF'
# Tablet Mode Configuration (Framework 12 2-in-1)
# Source this file in your hyprland.conf: source = ~/.config/hypr/tablet.conf
#
# On-Screen Keyboard (wvkbd):
#   - Keyboard: SUPER + ` (backtick/grave key - toggle OSK)
#   - Touch: Swipe from bottom edge upward (requires hyprgrass plugin)
#
# Display Rotation:
#   - Keyboard: SUPER + F7 (toggle 180° rotation for tablet mode)
#
# wvkbd shrinks all windows in your workspace when visible

# Start wvkbd-mobintl at login (visible by default, shows on-screen keyboard)
# The toggle-osk script or keybind can be used to hide/show it
exec-once = wvkbd-mobintl

# Toggle OSK with SUPER + ` (backtick/grave key)
bind = SUPER, grave, exec, toggle-osk

# Toggle display rotation with SUPER + F7 (for 2-in-1 tablet mode)
bind = SUPER, F7, exec, toggle-rotate

# Hyprgrass plugin configuration for touch gestures
# The hyprgrass plugin is installed via tiramisu packages (hyprlandPlugins.hyprgrass)
plugin {
  touch_gestures {
    # Sensitivity for touch gestures (1.0 = default)
    sensitivity = 1.0
    
    # Swipe from bottom edge upward to toggle OSK
    # This mimics mobile OS behavior
    hyprgrass-bind = , edge:d:u, exec, toggle-osk
    
    # Optional: Swipe from left edge for app launcher (wofi)
    # hyprgrass-bind = , edge:l:r, exec, pkill wofi || wofi --show drun
  }
}
EOF
    
    chmod 644 "$TABLET_CONF"
    
    # Check if tablet.conf is already sourced in hyprland.conf
    HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$HYPR_CONF" ]; then
      # Remove old osk.conf reference if present (we're migrating to tablet.conf)
      if grep -q "source.*osk.conf" "$HYPR_CONF" 2>/dev/null; then
        sed -i '/# On-Screen Keyboard configuration/d' "$HYPR_CONF"
        sed -i '/source.*osk.conf/d' "$HYPR_CONF"
      fi
      
      if ! grep -q "source.*tablet.conf" "$HYPR_CONF" 2>/dev/null; then
        # Add source line to end of hyprland.conf if not already present
        echo "" >> "$HYPR_CONF"
        echo "# Tablet mode configuration (OSK + display rotation)" >> "$HYPR_CONF"
        echo "source = ~/.config/hypr/tablet.conf" >> "$HYPR_CONF"
      fi
    fi
  '';
}
