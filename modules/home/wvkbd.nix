# On-Screen Keyboard (wvkbd) configuration for Framework 12 tablet mode
# Uses wvkbd-mobintl with hyprgrass for swipe gestures
# 
# Toggle methods:
#   1. Keybind: SUPER + K (toggle OSK)
#   2. Swipe: From bottom edge upward (via hyprgrass plugin)
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

in
lib.mkIf isTabletHost {
  # Add wvkbd and toggle script to user packages
  home.packages = with pkgs; [
    wvkbd        # Virtual keyboard for Wayland (wvkbd-mobintl variant)
    toggleOskScript
  ];

  # Seed Hyprland config snippets for OSK integration
  # These will be appended to the user's hyprland.conf via activation script
  home.activation.seedOskConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu
    
    # Create OSK config snippet for Hyprland
    OSK_CONF="$HOME/.config/hypr/osk.conf"
    mkdir -p "$HOME/.config/hypr"
    
    cat > "$OSK_CONF" << 'EOF'
# On-Screen Keyboard (wvkbd) Configuration
# Source this file in your hyprland.conf: source = ~/.config/hypr/osk.conf
#
# Toggle methods:
#   - Keyboard: SUPER + K
#   - Touch: Swipe from bottom edge upward (requires hyprgrass plugin)
#
# wvkbd shrinks all windows in your workspace when visible

# Start wvkbd-mobintl at login (visible by default, shows on-screen keyboard)
# The toggle-osk script or keybind can be used to hide/show it
exec-once = wvkbd-mobintl

# Toggle OSK with SUPER + K
bind = SUPER, K, exec, toggle-osk

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
    
    chmod 644 "$OSK_CONF"
    
    # Check if osk.conf is already sourced in hyprland.conf
    HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$HYPR_CONF" ]; then
      if ! grep -q "source.*osk.conf" "$HYPR_CONF" 2>/dev/null; then
        # Add source line to end of hyprland.conf if not already present
        echo "" >> "$HYPR_CONF"
        echo "# On-Screen Keyboard configuration" >> "$HYPR_CONF"
        echo "source = ~/.config/hypr/osk.conf" >> "$HYPR_CONF"
      fi
    fi
  '';
}
