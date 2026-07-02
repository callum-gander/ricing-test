{ config, pkgs, lib, ... }:
#
# USER LAYER (Home Manager).
# The key trick: we DON'T write Hyprland/Quickshell config in Nix. We keep them
# as plain files under ../dotfiles and symlink them in. That keeps the actual
# rice 100% portable to Fedora/Arch (just `pacman -S` the packages there and
# point at the same files).
#
let
  # Absolute path to this repo *inside the VM*. `mkOutOfStoreSymlink` links the
  # LIVE files here (not a copy in the nix store), so editing a dotfile takes
  # effect immediately (Hyprland + Quickshell hot-reload) with NO rebuild.
  # ⚠️ Clone the repo to exactly this path, or change it here.
  repo = "/home/callum/ricing-test";
in
{
  home.stateVersion = "25.11";   # match system.stateVersion

  # ---- The portable rice: symlink plain dotfiles into ~/.config ----
  xdg.configFile."hypr/hyprland.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/hypr/hyprland.conf";

  xdg.configFile."quickshell/shell.qml".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/quickshell/shell.qml";

  # ---- User packages ----
  home.packages = with pkgs; [
    quickshell   # QML desktop shell (release from nixpkgs)
    # To use bleeding-edge Quickshell instead, enable the flake input in flake.nix
    # and swap this for: inputs.quickshell.packages.${pkgs.system}.default
  ];

  programs.git.enable = true;
}
