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
    # nixpkgs Hyprland (0.55.x — what this VM already runs). Plugins come from
    # pkgs.hyprlandPlugins (same nixpkgs) so they're ABI-matched: a Hyprland
    # plugin MUST be built against the exact Hyprland it loads into.
  };

  # Lock screen — the module also sets up PAM so you can actually *unlock*.
  programs.hyprlock.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";   # hint Electron/Chromium → Wayland

  # ---- Login ----
  # initial_session = autologin into Hyprland on boot (safety net: you always land
  # straight in a session, and a reboot always recovers).
  # default_session = greeter shown on LOGOUT. In the VM we use tuigreet, a TTY
  # greeter that renders fine here. ReGreet (GTK4, below) is nicer but needs real
  # GL (blank in the VM) AND pulls cantarell-fonts, which currently fails to build
  # on aarch64 -- so it is gated to real hardware.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "Hyprland";
        user = "callum";
      };
      # If you enable programs.regreet (on metal), this mkIf steps aside so
      # ReGreet's own default_session (set via mkDefault) takes over -- one-liner.
      default_session = lib.mkIf (!config.programs.regreet.enable) {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # ReGreet -- graphical GTK4 greeter. METAL ONLY: won't render under the VM's GL,
  # and its default Cantarell font fails to build on aarch64. On real hardware just
  # set enable = true (it owns greetd's default_session; the mkIf above steps
  # aside). Optionally point programs.regreet.font at a font that's installed.
  programs.regreet = {
    enable = false;
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

  # ---- Fonts (Editorial Paper) ----
  #   JetBrainsMono Nerd Font — terminal + functional bar glyphs (icons)
  #   Playfair Display        — display serif: bar clock, ¶ wordmark, hyprlock, titles
  #   Noto Sans               — UI/body text: bar labels, launcher, notifications
  #   Noto Serif CJK SC       — the 一 二 三 workspace numerals
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts                # Noto Sans family
    noto-fonts-cjk-serif      # 一 二 三 — serif CJK for the workspace numerals
    # Just Playfair Display out of the Google Fonts set (keeps the closure small).
    # If the rebuild ever errors on the family name, replace this with plain `google-fonts`.
    (google-fonts.override { fonts = [ "Playfair Display" ]; })
  ];

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
