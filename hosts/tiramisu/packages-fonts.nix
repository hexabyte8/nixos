# 💫 https://github.com/JaKooLit 💫 #
# Packages for this host only (Framework 12 laptop with tablet mode)

{ pkgs, ... }:
let

  python-packages = pkgs.python3.withPackages (
    ps: with ps; [
      requests
      pyquery # needed for hyprland-dots Weather script
    ]
  );

in
{

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages =
    (with pkgs; [
      # System Packages
      fastfetch
    ])
    ++ [
      python-packages
    ];

  programs = {

    steam = {
      enable = true;
      gamescopeSession.enable = false;
      remotePlay.openFirewall = false;
      dedicatedServer.openFirewall = false;
    };

  };

}
