{
  description = "ricing-test — portable Hyprland + Quickshell rice, prototyped on NixOS in a VM";

  inputs = {
    # Use unstable so Hyprland / Quickshell / Mesa are fresh (Hyprland wants recent packages).
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OPTIONAL: track Quickshell's git directly instead of the nixpkgs release.
    # We default to `pkgs.quickshell` (from nixpkgs) for simplicity + stability.
    # Uncomment this and use `inputs.quickshell.packages.${system}.default` in
    # home/callum.nix if you want bleeding-edge Quickshell.
    #
    # quickshell = {
    #   url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    #   inputs.nixpkgs.follows = "nixpkgs";  # IMPORTANT: avoids ABI mismatches/crashes
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # aarch64-linux because the VM guest on an Apple Silicon Mac is ARM.
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/vm/hardware.nix        # VM-specific (disks etc.) — regenerate after install
        ./hosts/vm/configuration.nix   # the system layer (Nix-locked, but easy to redo on Arch/Fedora)

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Back up (rather than fail on) any pre-existing/reshaped dotfile that
          # collides during activation — avoids "would be clobbered" aborts.
          home-manager.backupFileExtension = "hm-bak";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.callum = import ./home/callum.nix;
        }
      ];
    };
  };
}
