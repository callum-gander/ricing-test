# ricing-test

A **portable Hyprland + Quickshell rice**, prototyped on **NixOS in a VM** on an Apple Silicon Mac.

The whole point: **your actual rice lives in plain files** (`dotfiles/`) that work on *any* distro.
NixOS is just the safe, reproducible sandbox to build and iterate in. When you're ready to
daily-drive, the same `dotfiles/` move to Fedora/Arch/openSUSE unchanged.

---

## Architecture — two layers

```
ricing-test/
├── flake.nix              ← entry point: pins nixpkgs + home-manager, defines the "vm" host
├── hosts/vm/
│   ├── configuration.nix  ← SYSTEM layer (Nix-locked; a checklist you'd redo via pacman on Arch)
│   └── hardware.nix       ← VM-specific disks — REGENERATE after install (the only non-portable file)
├── home/
│   └── callum.nix         ← USER layer: symlinks the dotfiles below into ~/.config
└── dotfiles/              ← ⭐ THE PORTABLE RICE — plain files, distro-agnostic
    ├── hypr/hyprland.conf
    └── quickshell/shell.qml
```

- **`dotfiles/`** = the rice. Plain `hyprland.conf` + `shell.qml`. Copy these to any distro forever.
- **Everything else** = Nix plumbing. Doesn't port verbatim, but each `enable = true` maps to a
  `pacman -S X && systemctl enable X` step elsewhere.

The dotfiles are linked with Home Manager's `mkOutOfStoreSymlink`, so **editing a dotfile hot-reloads
instantly — no rebuild.** You only rebuild when you change the *system* (packages, services).

> ⚠️ **Status:** this was scaffolded on macOS, where Nix can't run — so it has **not** been built or
> booted yet. The first real test is inside the VM (Step 4). Expect to tweak `hardware.nix` and maybe
> the `shell.qml` on first boot; that's normal.

---

## Step 1 — Install UTM

```sh
brew install --cask utm
```
(or download from https://mac.getutm.app)

## Step 2 — Get the NixOS ISO (ARM!)

Download the **minimal ISO for `AArch64`/ARM** from https://nixos.org/download
(the Mac VM is ARM, so you need the ARM image, not x86_64).

## Step 3 — Create the VM in UTM (settings that make Hyprland look good)

New VM → **Virtualize** → **Linux**, then in the VM's settings:

- **Do NOT tick "Use Apple Virtualization."** Keep UTM's QEMU backend — it's the one that supports
  **VirGL / virtio-gpu GL acceleration** for Linux guests (Apple's backend has weak Linux 3D).
- **Display → Emulated Display Card:** pick a **virtio-gpu option labeled "GPU Supported" / GL**.
  This is what gives Hyprland smooth, accelerated animations.
- **System:** 4096+ MB RAM, 4 CPU cores.
- **Storage:** 32 GB+ (the `/nix/store` grows).
- Enable **clipboard sharing** (the config already installs the SPICE agent).
- Attach the NixOS ISO and boot it.

## Step 4 — Install NixOS from the ISO, using this repo

Boot the ISO to a shell, then (rough outline — follow the official manual for partitioning):

```sh
# 1. Partition + format your virtual disk. LABEL them to match hardware.nix:
#    - ESP  (fat32) labelled "boot"
#    - root (ext4)  labelled "nixos"
#    Then mount root at /mnt and the ESP at /mnt/boot.

# 2. Generate hardware config for THIS machine:
sudo nixos-generate-config --root /mnt

# 3. Get this repo (enable git/flakes in the installer first):
nix-shell -p git
git clone <your-repo-url> /mnt/home/callum/ricing-test
#   ^ MUST land at /home/callum/ricing-test — home/callum.nix hardcodes that path.

# 4. Replace the placeholder hardware file with the real generated one:
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/home/callum/ricing-test/hosts/vm/hardware.nix

# 5. Set system.stateVersion in configuration.nix to your ISO's release:
nixos-version        # e.g. 25.11 → make sure it matches (also home/callum.nix)

# 6. Install from the flake:
sudo nixos-install --flake /mnt/home/callum/ricing-test#vm

reboot
```

First boot **autologins straight into Hyprland**. Open a terminal with **`Super`+`Return`**.
Log in for shell/sudo with user `callum`, password `nixos` (change it: `passwd`).

---

## The daily loop

| You changed…                          | Do this                                        |
|---------------------------------------|------------------------------------------------|
| A **dotfile** (`hyprland.conf`, `shell.qml`) | Just save — it **hot-reloads**. No rebuild.    |
| The **system** (packages, services)   | `sudo nixos-rebuild switch --flake ~/ricing-test#vm` |
| You **broke** something               | Reboot → pick the previous generation in the boot menu. Or `sudo nixos-rebuild switch --rollback`. |
| Store getting big                     | `sudo nix-collect-garbage -d`                  |

Default keybinds: `Super+Return` terminal · `Super+D` launcher · `Super+Q` close · `Super+1..4`
workspaces · `Print` screenshot region. (All editable in `dotfiles/hypr/hyprland.conf`.)

---

## Moving to a real distro later (the payoff)

Nothing here locks you in. When you pick a daily driver (Fedora Hyprland spin, Arch, Tumbleweed…):

1. Install it normally.
2. `dnf/pacman/zypper install hyprland quickshell kitty fuzzel mako ...` (the `systemPackages` list
   in `configuration.nix` is your shopping list).
3. Symlink the **same** `dotfiles/` into `~/.config` (via GNU stow, chezmoi, or plain `ln -s`).

Same rice, different substrate. The hard work — `dotfiles/` — was done once, here.

---

## Sharp-edge cheatsheet (NixOS)

- **Cryptic errors / the Nix language** — the #1 pain. Search https://search.nixos.org for option names.
- **A downloaded binary won't run** — that's the missing-loader issue; `programs.nix-ld.enable`
  (already on) fixes most. For stubborn cases wrap with an FHS env.
- **"Which way is right?"** — for system config, use the NixOS/Home-Manager *modules* (as here),
  not `nix-env`/imperative installs.
- **New vs old CLI** — prefer `nix build` / `nixos-rebuild --flake` (new). Ignore `nix-build` tutorials.
- **Quickshell won't draw** — run `quickshell` in a terminal to read QML errors; the starter
  `shell.qml` is intentionally minimal.
