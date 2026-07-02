{ config, pkgs, lib, inputs, ... }:
#
# SYSTEM LAYER — this is the Nix-specific part.
# It does NOT port verbatim to Fedora/Arch, but every `enable = true` here maps
# to a "pacman -S X + systemctl enable X" step there. Think of it as a checklist
# of what a Hyprland desktop needs, written in Nix.
#
{
  # ---- Boot (UEFI; UTM ARM VMs boot UEFI) ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- Plymouth boot splash (animated; quiet boot) ----
  boot.plymouth.enable = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "virtio_gpu" ];   # early DRM so Plymouth has something to draw on
  boot.kernelParams = [ "quiet" "splash" ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  # ---- Networking ----
  networking.hostName = "vm";
  networking.networkmanager.enable = true;

  # ---- SSH (tinker from your Mac's Terminal — paste-friendly, no TTY dance) ----
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;   # fine for a local VM; ssh callum@<vm-ip>
  };

  # ---- Locale / time (change to taste) ----
  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- User ----
  users.users.callum = {
    isNormalUser = true;
    description = "callum";
    initialPassword = "nixos";                       # CHANGE after first login: `passwd`
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };

  # ---- Nix: turn on flakes + the new CLI ----
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Hyprland's binary cache — download prebuilt Hyprland/plugins instead of a long compile.
  nix.settings.extra-substituters = [ "https://hyprland.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  nixpkgs.config.allowUnfree = true;

  # ---- SHARP-EDGE MITIGATION ----
  # Lets downloaded dynamic ELF binaries (some pip/npm native pkgs, AppImages,
  # proprietary tools) actually run on NixOS. You WILL want this eventually.
  programs.nix-ld.enable = true;

  # ---- GPU userspace (Mesa incl. virtio/virgl driver) — needed for Hyprland GL ----
  hardware.graphics.enable = true;

  # ---- Bluetooth (no adapter in the VM, but wired up for real hardware) ----
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ---- Wayland compositor ----
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;                       # flake Hyprland (for plugins)
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  # Lock screen — the module also sets up PAM so you can actually *unlock*.
  programs.hyprlock.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";   # hint Electron/Chromium → Wayland

  # ---- Login ----
  # initial_session = autologin into Hyprland on boot. This is the SAFETY NET:
  # even if the graphical greeter can't render under the VM's limited GL, boot
  # still lands you in a session (reboot always recovers). The greeter shown on
  # LOGOUT is ReGreet (programs.regreet below) — it owns greetd's default_session
  # via mkDefault, running ReGreet inside a `cage` kiosk compositor.
  services.greetd = {
    enable = true;
    settings.initial_session = {
      command = "Hyprland";
      user = "callum";
    };
  };

  # ReGreet — graphical greetd greeter (GTK4). A portable win for real hardware
  # (Fedora); in the VM it may render blank (GTK4/GL), but the autologin above
  # means that's harmless. Pulls in `cage` automatically.
  programs.regreet = {
    enable = true;
    settings.GTK.application_prefer_dark_theme = true;
  };

  # ---- Portals (screenshare, file pickers) ----
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # programs.hyprland already wires up xdg-desktop-portal-hyprland.
  };

  # ---- Audio (PipeWire) ----
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ---- Fonts (Nerd Font for bar glyphs/icons) ----
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # ---- Minimal Wayland rice toolkit (system-wide) ----
  environment.systemPackages = with pkgs; [
    git vim wget curl
    ghostty        # GPU-accelerated terminal — our default (may be GL-limited in the VM)
    foot           # CPU-rendered terminal — rock-solid fallback: Super+Shift+Return
    kitty          # GPU terminal; segfaults on this VM's EGL — kept for reference only
    fuzzel         # app launcher (kept; rofi is now the default $menu)
    rofi           # fuller launcher (drun/run/window); rofi-wayland was merged into rofi
    mako           # (kept; swaync is now the notification daemon)
    swaynotificationcenter   # notifications + control centre
    hypridle       # idle daemon (hyprlock itself comes via programs.hyprlock)
    hyprpaper      # wallpaper daemon (needs an image; awww/swaybg are alternatives)
    swaybg         # dead-simple solid-colour background — our current Mocha backdrop
    wl-clipboard   # clipboard
    grim slurp     # screenshots
    brightnessctl  # no-op in a VM, handy on real hardware

    # ---- Control-centre tools (tray applets + audio/bt/display selectors) ----
    libnotify              # notify-send
    pavucontrol            # audio device selection (click the bar's volume)
    blueman                # bluetooth manager + blueman-applet (tray)
    networkmanagerapplet   # nm-applet (network tray icon)
    nwg-displays           # display / monitor arrangement (Super+P)
    playerctl              # media control
    btop                   # system monitor (resources popup → "Open btop")
    (mpv.override { scripts = [ mpvScripts.mpris ]; })   # media player WITH mpris (drives the bar's now-playing)
  ];

  # ---- VM guest niceties (clipboard sharing / dynamic resize with UTM) ----
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Keep this at the release your ISO reports (`nixos-version`). Do NOT bump casually.
  system.stateVersion = "25.11";
}
