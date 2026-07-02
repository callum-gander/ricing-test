{ config, pkgs, lib, ... }:
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

  # ---- Networking ----
  networking.hostName = "vm";
  networking.networkmanager.enable = true;

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
  nixpkgs.config.allowUnfree = true;

  # ---- SHARP-EDGE MITIGATION ----
  # Lets downloaded dynamic ELF binaries (some pip/npm native pkgs, AppImages,
  # proprietary tools) actually run on NixOS. You WILL want this eventually.
  programs.nix-ld.enable = true;

  # ---- GPU userspace (Mesa incl. virtio/virgl driver) — needed for Hyprland GL ----
  hardware.graphics.enable = true;

  # ---- Wayland compositor ----
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";   # hint Electron/Chromium → Wayland

  # ---- Login: autologin straight into Hyprland (frictionless VM playground) ----
  # If you log out, tuigreet appears so you can pick a session.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "Hyprland";
        user = "callum";
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
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
    kitty          # terminal (needs GL ≥3.3 — flaky in the VM, kept as a fallback)
    foot           # CPU-rendered terminal — reliable in VMs; our default (see hyprland.conf $term)
    fuzzel         # app launcher
    mako           # notification daemon
    hyprpaper      # wallpaper daemon (enable in hyprland.conf when you add an image)
    wl-clipboard   # clipboard
    grim slurp     # screenshots
    brightnessctl  # no-op in a VM, handy on real hardware
  ];

  # ---- VM guest niceties (clipboard sharing / dynamic resize with UTM) ----
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Keep this at the release your ISO reports (`nixos-version`). Do NOT bump casually.
  system.stateVersion = "25.11";
}
