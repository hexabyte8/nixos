# 💫 https://github.com/JaKooLit 💫 #
# Packages and Fonts config including the "programs" options

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

      #waybar  # if wanted experimental next line
      #(pkgs.waybar.overrideAttrs (oldAttrs: { mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];}))
    ])
    ++ [
      python-packages
    ];

  programs = {

    steam = {
      enable = false;
      gamescopeSession.enable = false;
      remotePlay.openFirewall = false;
      dedicatedServer.openFirewall = false;
    };

  };

}
