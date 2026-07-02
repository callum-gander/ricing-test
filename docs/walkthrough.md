# ricing-test — annotated build log

A step-by-step, *explained* record of standing up this NixOS + Hyprland + Quickshell
rice as an ARM VM in UTM on an Apple Silicon Mac. Written to be **studied later** — every
command has a "what / why," and there's a glossary at the end.

Started: 2026-07-02 · Host: Apple Silicon Mac (arm64), macOS 26.5 · Guest: NixOS 25.11 (aarch64)

---

## 0. The mental model (read this first)

Two layers, kept deliberately separate:

- **System layer** (Nix-specific): `flake.nix`, `hosts/vm/*`, `home/callum.nix`. Declares the whole
  machine — packages, services, the compositor. Does *not* port verbatim to other distros, but every
  `enable = true` maps to a "install package + enable service" step elsewhere.
- **Rice layer** (portable): `dotfiles/hypr/hyprland.conf`, `dotfiles/quickshell/shell.qml`. Plain
  files that work on **any** distro. This is the part we actually care about long-term; NixOS is just
  the safe sandbox to build it in.

The trick that ties them together: Home Manager symlinks the plain dotfiles into `~/.config` using
`mkOutOfStoreSymlink`, which links the **live files** (not copies), so editing a dotfile hot-reloads
instantly with no rebuild. See [glossary](#glossary).

Why a VM at all: so the real Linux desktop stays untouched, and NixOS's atomic rollback means we
literally cannot brick it — worst case we boot the previous generation.

---

## 1. Host prep (on the Mac)

### 1.1 Install UTM
```sh
brew install --cask utm
```
**What/why:** UTM is a GUI VM manager. On Apple Silicon it can run ARM Linux guests at near-native
speed. We use its **QEMU backend** (not Apple's Virtualization framework) because QEMU exposes
**virtio-GPU with GL acceleration** to Linux guests — that's what makes Hyprland's animations smooth.

### 1.2 Download the NixOS ISO (ARM, minimal)
```
https://channels.nixos.org/nixos-25.11/latest-nixos-minimal-aarch64-linux.iso
```
**What/why:** `aarch64` because the guest is ARM (matches the Mac's CPU — x86 images would have to be
*emulated*, which is slow). `minimal` = a console-only installer (no desktop), which is what we want
since we install our *own* config from the flake, not a pre-baked desktop.

### 1.3 Create the VM in UTM
- **+ → Virtualize → Linux.**
- **Leave "Use Apple Virtualization" UNCHECKED** → keeps the QEMU backend (for GL, see 1.1).
- Boot ISO Image → the `.iso` from 1.2.
- Memory **4096 MB**, CPU **4 cores**, Storage **32 GB**.
- **Settings → Display → Emulated Display Card →** pick an option ending in **"(GPU Supported)"**
  (e.g. `virtio-gpu-gl-pci`). This enables VirGL/GL acceleration in the guest.

### 1.4 Publish the repo so the VM can pull it (Mac-side git)
```sh
git -C ~/Desktop/coding/ricing-test commit -q -m "Initial scaffold: NixOS VM flake + portable Hyprland/Quickshell rice"
gh repo create ricing-test --public --source=~/Desktop/coding/ricing-test --push \
  --description "Portable Hyprland + Quickshell rice, prototyped on NixOS in a VM"
```
**What/why:** the flake config uses `mkOutOfStoreSymlink` pointing at `/home/callum/ricing-test`, so
the actual repo files must live at that path *inside* the VM. Easiest transfer: push to GitHub, clone
in the VM (a public repo clones with no auth). Result: <https://github.com/callum-gander/ricing-test>.

---

## 2. Boot the installer

Start the VM. The minimal ISO auto-logs in as the **`nixos`** user (not root — so everything below
uses `sudo`) and lands at:
```
[nixos@nixos:~]$
```

### 2.1 (Recommended) SSH in from the Mac so you can paste
```bash
sudo passwd nixos        # set any temp password
ip -4 a | grep 192       # find the VM's IP (UTM shared net → usually 192.168.64.x)
```
Then from the Mac's Terminal: `ssh nixos@THAT_IP`.
**Why:** the VM console has no clipboard, and typing partition commands by hand is error-prone. SSH
lets you paste the rest. The installer runs `sshd` already; you just need a password on `nixos`.

---

## 3. Phase 2a — partition, format, mount

> **The `/mnt` mental model.** You're running off the ISO (a live OS in RAM). The VM's blank 32 GB
> disk (`/dev/vda`) is separate — to write the new system onto it you must *mount* it somewhere, and
> `/mnt` is the conventional scratch mountpoint. So **`/mnt` = the future `/`**. After install +
> reboot the `/mnt` prefix falls away. Mapping:
>
> | In the installer (now)             | After reboot (real system)        |
> |------------------------------------|-----------------------------------|
> | `/mnt`                             | `/`                               |
> | `/mnt/boot`                        | `/boot`                           |
> | `/mnt/home/callum/ricing-test`     | `/home/callum/ricing-test`        |
> | `/mnt/etc/nixos/hardware-…nix`     | `/etc/nixos/hardware-…nix`        |

```bash
lsblk
```
**What/why:** list block devices. Confirm the blank disk is `/dev/vda` (~32 G, no partitions yet)
before touching it. (In a UTM QEMU VM the virtio disk is `vda`.)

```bash
sudo parted /dev/vda -- mklabel gpt
sudo parted /dev/vda -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/vda -- set 1 esp on
sudo parted /dev/vda -- mkpart root ext4 512MiB 100%
```
**What/why:** create a **GPT** partition table, then two partitions:
- **p1 (512 MiB, FAT32, `esp` flag):** the **EFI System Partition** — where the UEFI firmware reads
  the bootloader (systemd-boot). Must be FAT.
- **p2 (rest):** the root filesystem. `parted`'s `ext4`/`fat32` args here are just *hints/labels* —
  they don't actually format; that's the next step.

```bash
sudo mkfs.fat -F 32 -n boot /dev/vda1
sudo mkfs.ext4 -L nixos /dev/vda2
```
**What/why:** actually create the filesystems. `-n boot` / `-L nixos` set volume labels (handy).

```bash
sudo mount /dev/vda2 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/vda1 /mnt/boot
```
**What/why:** mount root at `/mnt` and the ESP at `/mnt/boot`, i.e. assemble the future filesystem
tree so the installer can write into it. (Validate anytime with `findmnt /mnt /mnt/boot`.)

```bash
sudo nixos-generate-config --root /mnt
```
**What/why:** scans this machine's hardware and writes `/mnt/etc/nixos/hardware-configuration.nix`
(real disk UUIDs, kernel modules) + a starter `configuration.nix`. We only keep the **hardware** file
— it's the one machine-specific, non-portable piece.

---

## 4. Phase 2b — pull the repo in, drop in the real hardware config

```bash
sudo mkdir -p /mnt/home/callum
sudo nix-shell -p git --run "git clone https://github.com/callum-gander/ricing-test.git /mnt/home/callum/ricing-test"
```
**What/why:** the minimal ISO has no `git`, so `nix-shell -p git` fetches it temporarily and runs the
clone. We clone into `/mnt/home/callum/ricing-test` so it becomes `/home/callum/ricing-test` after
reboot — the exact path the flake's `mkOutOfStoreSymlink` expects.

```bash
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/callum/ricing-test/hosts/vm/hardware.nix
```
**What/why:** replace the repo's **placeholder** `hardware.nix` with *this VM's real* generated one.
This is the single file that stays VM-specific.

```bash
sudo chown -R 1000:100 /mnt/home/callum
```
**What/why:** the clone was made as root. We set ownership to uid `1000` : gid `100` — which is
`callum` : `users` (the first normal NixOS user gets uid 1000, group `users`). Doing it *before* first
boot means (a) Home Manager can write into the home dir during activation, and (b) you can edit the
dotfiles without `sudo`. We use numbers because the `callum` user doesn't exist yet in the installer.

---

## 5. Phase 2c — install

```bash
sudo nixos-install --flake /mnt/home/callum/ricing-test#vm
```
**What/why:** builds the `nixosConfigurations.vm` output from the flake and installs it onto `/mnt`,
then installs the bootloader.
- Expect **lots of downloading + several minutes** — it resolves `nixpkgs-unstable` + `home-manager`
  and builds the world (first install always does).
- A **"Git tree is dirty"** warning is expected and harmless — that's the `hardware.nix` we just
  copied in over a tracked file. Nix still uses the modified content.
- There's no `flake.lock` in the repo yet, so this step **generates** one (pins exact input versions).
- At the end it prompts for a **root password** — set one you'll remember.

---

## 6. Reboot into the installed system

```bash
sudo poweroff
```
Then in **UTM: remove the ISO** (VM Settings → the CD/DVD drive → clear/eject) so UEFI boots the disk,
not the installer again. Start the VM.

**What success looks like:** `greetd` auto-logs into Hyprland → a dark screen with the Quickshell bar
at the top (`ricing-test` + live clock). `Super+Return` = terminal (kitty), `Super+D` = launcher
(fuzzel). For sudo, log in as `callum` / password `nixos` (change with `passwd`).

**If you get a black screen or a text login prompt instead:** Hyprland failed to start — almost
certainly the VM GL path. Not a real breakage (rollback = previous generation). Fixes to try:
change the UTM display card, or add a software-render fallback env to `configuration.nix`.

---

## 7. The daily loop (post-install)

| You changed…                              | Do this                                                    |
|-------------------------------------------|------------------------------------------------------------|
| a **dotfile** (`hyprland.conf`, `shell.qml`) | just save — **hot-reloads**, no rebuild                     |
| the **system** (packages, services)       | `sudo nixos-rebuild switch --flake ~/ricing-test#vm`        |
| you **broke** something                   | reboot → pick the previous generation; or `nixos-rebuild switch --rollback` |
| `/nix/store` getting big                  | `sudo nix-collect-garbage -d`                               |

---

## Gotchas we hit

**`error: attribute 'tuigreet' missing` during `nixos-install` (first attempt).**
The greetd `default_session` referenced `${pkgs.greetd.tuigreet}` — the *old* attribute path that
lots of blog posts still use. On current nixpkgs, tuigreet lives at `pkgs/by-name/tu/tuigreet/`, so
the correct attribute is the **top-level `pkgs.tuigreet`**. Fixed in `hosts/vm/configuration.nix`.

Two takeaways worth remembering:
- A flake that fails to **evaluate** installs *nothing* — the partitioning/clone were untouched, so
  the fix was just: correct the file, re-sync the VM's clone, re-run `nixos-install`.
- When docs and the actual eval error disagree, **the eval error wins** — it reflects the exact
  nixpkgs commit you pinned. Confirm attribute paths against `pkgs/by-name/…` in nixpkgs.

**First boot: two Hyprland config errors + kitty wouldn't stay open.**
- `dwindle:pseudotile does not exist` — `pseudotile` was removed as a dwindle *option* (pseudo is now
  a per-window dispatcher). Fix: deleted the line.
- `Invalid dispatcher 'togglesplit'` — `togglesplit` is a **layout message**, not a top-level
  dispatcher. Fix: `bind = $mod, Space, layoutmsg, togglesplit`.
- **kitty opened then instantly closed** — the journal confirmed a hard crash:
  `.kitty-wrapped … terminated abnormally with signal 11/SEGV … Module libEGL.so.1`. The VM's virgl
  can give the *compositor* a GLES context (so Hyprland runs) but can't give **kitty** the desktop-GL
  context it wants — kitty segfaults inside EGL. Fix: switched the default terminal to **foot**, which
  renders on the CPU and needs no GL — the standard choice for VMs. (No `quickshell` coredumps
  appeared, so the bar process is fine — Qt Quick tolerates the GL situation.)
- Enabled `services.openssh` so the VM can be driven from the Mac's Terminal (`ssh callum@<vm-ip>`),
  avoiding the console/VT dance for future edits.
- Harmless warning `Hyprland was started without start-hyprland` — it's launched directly by greetd
  rather than via a session wrapper (uwsm); fine for this playground, can be wrapped later.

Reminder: `hyprland.conf` edits **hot-reload** (no rebuild). Installing `foot` is a *system* change,
so that one needs `sudo nixos-rebuild switch`.

## Ricing pass 1 — Catppuccin Mocha

Everything here is **plain, portable dotfiles** (the whole point) — they'd move to Fedora/Arch
unchanged. `hyprland.conf`, `shell.qml`, and the app themes **hot-reload**; installing `swaybg` was
the only *system* change (one `nixos-rebuild`).

- **Palette:** Catppuccin Mocha (base `#1e1e2e`, text `#cdd6f4`, accents blue `#89b4fa` / mauve `#cba6f7`).
- **`dotfiles/foot/foot.ini`** — terminal: Mocha colours, padding, 94% opacity (blurred by Hyprland).
- **`dotfiles/fuzzel/fuzzel.ini`** — launcher: Mocha, rounded, accent border.
- **`dotfiles/mako/config`** — notifications: Mocha, rounded; red border for urgent.
- **`dotfiles/quickshell/shell.qml`** — the bar became real: snowflake logo · **live workspaces**
  (`Quickshell.Hyprland`, click to switch) · date/clock · **live volume** (`Quickshell.Services.Pipewire`).
- **`dotfiles/hypr/hyprland.conf`** — `swaybg` solid backdrop, subtle window opacity, blur behind the bar.

Gotcha logged: Nerd Font glyphs pasted into `shell.qml` kept getting stripped to empty strings in
transmission, so icons are built with `String.fromCharCode(0xXXXX)` (pure ASCII) rather than literal glyphs.

**Wallpaper note:** `swww` was renamed to **awww** (https://codeberg.org/LGFae/awww) and is **not in
nixpkgs** — it needs a flake input (`inputs.awww.url = "git+https://codeberg.org/LGFae/awww"`). We used a
solid `swaybg` backdrop first for reliability; awww (animated wallpapers) is the next step and doubles as
a lesson in pulling a package nixpkgs doesn't have.

## Glossary

- **flake** — a repo with a standard `flake.nix` entry point that declares *inputs* (dependencies like
  nixpkgs) and *outputs* (here, `nixosConfigurations.vm`). Reproducible + pinned.
- **flake.lock** — a lockfile pinning the exact commit of every input (like `Cargo.lock`). Generated
  on first build.
- **generation** — an immutable snapshot of your whole system produced by each rebuild. They're listed
  in the boot menu; rolling back = booting an older one.
- **nixpkgs-unstable** — the rolling, always-fresh package set (we use it so Hyprland/Mesa are recent).
- **Home Manager** — the tool that manages *user-level* config/dotfiles/packages declaratively.
- **mkOutOfStoreSymlink** — a Home Manager helper that symlinks to a **live path on disk** instead of a
  read-only copy in the Nix store → lets you edit dotfiles and have them hot-reload without a rebuild.
- **greetd** — a minimal login daemon; we configure it to auto-launch Hyprland (with `tuigreet` as a
  fallback greeter if you log out).
- **Hyprland** — a dynamic tiling **Wayland compositor**, very customizable, big ricing community.
- **Quickshell** — a QML/QtQuick toolkit for building your *own* desktop shell (bar, widgets,
  launcher). Config lives in `~/.config/quickshell/shell.qml`.
- **nix-ld** — a shim that lets normal downloaded dynamic binaries run on NixOS (which lacks the usual
  loader paths). Pre-enabled here to dodge a classic NixOS sharp edge.
- **virtio-gpu / VirGL** — paravirtualized GPU that passes guest OpenGL through to the host for
  acceleration. The reason we picked UTM's QEMU backend + a "(GPU Supported)" display card.
- **ESP (EFI System Partition)** — a small FAT partition the UEFI firmware reads the bootloader from.
- **GPT** — the modern partition table format (pairs with UEFI).
</content>
