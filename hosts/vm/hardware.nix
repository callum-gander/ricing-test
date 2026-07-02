#
# ⚠️  PLACEHOLDER — REPLACE THIS FILE after installing NixOS in the VM.
#
# This is the ONE machine-specific, non-portable file (real disk layout).
#
# During install:   nixos-generate-config --root /mnt
# then copy         /mnt/etc/nixos/hardware-configuration.nix   over this file.
# (or after first boot, copy /etc/nixos/hardware-configuration.nix here.)
#
# TIP: if you label your partitions `nixos` (root) and `boot` (ESP) during
# install, the dummy filesystems below may work as-is — but regenerating is safer.
#
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # ⚠️  Replace with your real filesystems from nixos-generate-config.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
