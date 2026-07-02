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

  xdg.configFile."foot/foot.ini".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/foot/foot.ini";
  xdg.configFile."fuzzel/fuzzel.ini".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/fuzzel/fuzzel.ini";
  xdg.configFile."mako/config".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/mako/config";
  xdg.configFile."ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/ghostty/config";

  # ---- Batch 1: CLI / dev rice configs ----
  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/starship.toml";
  xdg.configFile."zellij/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/zellij/config.kdl";
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/dotfiles/nvim";

  # ---- User packages ----
  home.packages = with pkgs; [
    quickshell   # QML desktop shell (release from nixpkgs)
    # To use bleeding-edge Quickshell instead, enable the flake input in flake.nix
    # and swap this for: inputs.quickshell.packages.${pkgs.system}.default

    # ---- Batch 1: CLI / dev rice ----
    starship          # prompt
    fastfetch         # system info + logo
    zellij            # terminal multiplexer
    lazygit           # git TUI
    eza bat           # nicer ls / cat
    # Neovim (LazyVim) + runtime deps
    neovim
    ripgrep fd        # telescope grep / find
    gcc gnumake       # treesitter parser compilation
    nodejs            # some tools / LSPs
    unzip             # mason downloads (mason LSP *binaries* need nix-ld on NixOS)
    tree-sitter
    lua-language-server stylua   # for editing the nvim config itself
  ];

  programs.git.enable = true;

  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(starship init bash)"
      alias ls="eza --icons --group-directories-first"
      alias ll="eza -l --icons --git --group-directories-first"
      alias la="eza -la --icons --git --group-directories-first"
      alias cat="bat --paging=never"
    '';
  };
}
