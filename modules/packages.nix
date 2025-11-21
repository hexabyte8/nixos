{
  pkgs,
  inputs,
  host,
  ...
}:
{

  programs = {
    hyprland = {
      enable = true;
      withUWSM = false;
      #package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland; #hyprland-git
      #portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland; #xdph-git

      portalPackage = pkgs.xdg-desktop-portal-hyprland; # xdph none git
      xwayland.enable = true;
    };
    zsh.enable = true;
    firefox.enable = true;
    waybar.enable = true;
    hyprlock.enable = true;
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    git.enable = true;
    tmux.enable = true;
    nm-applet.indicator = true;
    neovim = {
      enable = true;
      defaultEditor = false;
    };

    thunar.enable = true;
    thunar.plugins = with pkgs.xfce; [
      exo
      mousepad
      thunar-archive-plugin
      thunar-volman
      tumbler
    ];

  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
        curseforge = pkgs.stdenv.mkDerivation {
          name = "curseforge";
          src = builtins.path { path = ../curseforge-latest-linux.deb; };
          unpackPhase = ''
            dpkg-deb -x $src .
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp -r usr/* $out/
            # Create a symlink for easier access
            ln -s $out/share/curseforge/curseforge $out/bin/curseforge
          '';
          nativeBuildInputs = [ pkgs.dpkg ];
        };
    };

  environment.systemPackages = with pkgs; [

    # Update flkake script
    (pkgs.writeShellScriptBin "fupdate" ''
      cd ~/NixOS-Hyprland
      nh os switch -u -H ${host} .
    '')

    # Rebuild flkake script
    (pkgs.writeShellScriptBin "frebuild" ''
      cd ~/NixOS-Hyprland
      nh os switch -H ${host} .
    '')

    # clean up old generations
    (writeShellScriptBin "ncg" ''
      nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot
    '')

    # Hyprland Stuff

    hypridle
    hyprpolkitagent
    pyprland
    #uwsm
    hyprlang
    zip
    hyprshot
    hyprcursor
    mesa
    nwg-displays
    nwg-look
    waypaper
    hyprland-qt-support # for hyprland-qt-support

    #  Apps
    loupe
    bc
    brightnessctl
    (btop.override {
      cudaSupport = true;
      rocmSupport = true;
    })
    bottom
    baobab
    bind
    btrfs-progs
    cmatrix
    dua
    duf
    cava
    cargo
    clang
    cmake
    cliphist
    cpufrequtils
    curl
    dysk
    eog
    eza
    findutils
    figlet
    ffmpeg
    fd
    feh
    file-roller
    glib # for gsettings to work
    gsettings-qt
    git
    google-chrome
    gnome-system-monitor
    fastfetch
    jq
    gcc
    git
    gnumake
    grim
    grimblast
    gtk-engine-murrine # for gtk themes
    inxi
    imagemagick
    killall
    kdePackages.qt6ct
    kdePackages.qtwayland
    kdePackages.qtstyleplugin-kvantum # kvantum
    lazydocker
    libappindicator
    libnotify
    libsForQt5.qtstyleplugin-kvantum # kvantum
    libsForQt5.qt5ct
    (mpv.override { scripts = [ mpvScripts.mpris ]; }) # with tray
    nvtopPackages.full
    openssl # required by Rainbow borders
    pciutils
    networkmanagerapplet
    #nitrogen
    #nvtopPackages.full
    pamixer
    pavucontrol
    halloy
    playerctl
    #polkit
    # polkit_gnome
    kdePackages.polkit-kde-agent-1
    # qt6ct
    #qt6.qtwayland
    #qt6Packages.qtstyleplugin-kvantum # kvantum
    # gsettings-qt
    rofi
    slurp
    swappy
    swaynotificationcenter
    swww
    tree
    obsidian
    unzip
    wallust
    wdisplays
    wl-clipboard
    wlr-randr
    wlogout
    wget
    xarchiver
    yad
    yazi
    yt-dlp

    (inputs.quickshell.packages.${pkgs.system}.default)
    (inputs.ags.packages.${pkgs.system}.default)

    # Utils
    ansible
    caligula # burn ISOs at cli FAST
    atop
    gdu
    glances
    gping
    htop
    hyfetch
    ipfetch
    lolcat
    opencode
    lsd
    oh-my-posh
    pfetch
    ncdu
    ncftp
    ripgrep
    socat
    starship
    tldr
    ugrep
    unrar
    v4l-utils
    scanmem
    obs-studio
    zoxide

    # Hardware related
    cpufetch
    cpuid
    cpu-x
    #gsmartcontrol
    smartmontools
    light
    lm_sensors
    mission-center
    neofetch

    # Development related
    luarocks
    nh


    # Virtuaizaiton
    virt-viewer
    libvirt

    # Video
    vlc
    vesktop

    # Terminals
    kitty
    wezterm

  ];

}
