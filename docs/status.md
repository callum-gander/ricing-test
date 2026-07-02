# ricing-test — status / current state

A **Catppuccin Mocha Hyprland + Quickshell rice**, prototyped as an **aarch64 NixOS VM in UTM**
on an Apple Silicon Mac. The actual rice lives in **plain portable dotfiles** (`dotfiles/`);
NixOS is just the reproducible sandbox. Eventual daily-driver target: **Fedora (Hyprland spin)**.

## Where things live / workflow
- **Repo:** `/Users/callum/Desktop/coding/ricing-test` (Mac) → GitHub `callum-gander/ricing-test`.
- **VM:** NixOS aarch64 in UTM. `ssh callum@192.168.64.5` (pw `nixos`). sudo pw `nixos`.
- **Edit loop:** edit on Mac → `git commit`/`push` → in VM `cd ~/ricing-test && git pull`.
  - Most dotfiles **hot-reload** (Quickshell `shell.qml`, foot/rofi/mako/swaync, shaders via `hyprctl reload`).
  - **`hyprland.conf` does NOT hot-reload** — it's a read-only `/nix/store` copy; changes need
    `sudo nixos-rebuild switch --flake ~/ricing-test#vm` then a `hyprctl reload` or session restart.
  - **Packages / NixOS options / plugins** → always need `nixos-rebuild switch`.
- **Plugins load on SESSION START** (via an `exec-once` loader — see Plugins below). After a rebuild
  that touches plugins, **restart the Hyprland session** (`Super+Shift+E` → autologin, or `sudo reboot`)
  or they won't be active. `hyprctl plugin list` should be non-empty once loaded.
- **If the Quickshell bar vanishes** (QML error): `pkill -f quickshell; quickshell` in a terminal.

## Config architecture
- `flake.nix` — inputs are just **nixpkgs (unstable) + home-manager**. HM has `backupFileExtension = "hm-bak"`
  (so a reshaped/pre-existing dotfile is backed up, not a "would be clobbered" abort). Passes `inputs`
  via specialArgs/extraSpecialArgs (currently unused by the modules — harmless).
- `hosts/vm/configuration.nix` — system layer. **Uses the nixpkgs Hyprland** (no flake package override).
  greetd, PipeWire, fonts, all system packages.
- `hosts/vm/hardware.nix` — VM disks (the one non-portable file; regenerated at install).
- `home/callum.nix` — home-manager: symlinks dotfiles into `~/.config`, the plugin loader, user apps, wallpaper.
  - Most dotfiles use `mkOutOfStoreSymlink` (live/hot-reload).
  - **`hyprland.conf` is a read-only store COPY** (`.source = ../dotfiles/...`), NOT a symlink — see gotcha.
  - **`hypr/shaders` is a whole-DIR symlink** (so both `glow.frag` + `bloom.frag` are live).
- `dotfiles/` — the portable rice.

> **We are NOT using the Hyprland flake.** We tried it to get first-party plugins, but the official
> `hyprland-plugins` flake **dropped hyprexpo + hyprtrails as unmaintained** (gone since v0.55), which made
> the loader reference a missing attribute and **aborted every rebuild at eval** (that's why apps/plugins/greeter
> silently never installed for a while). nixpkgs Hyprland + nixpkgs `hyprlandPlugins` is simpler, needs no
> compile, and is guaranteed ABI-matched. (A stale, now-unused `hyprland.cachix.org` substituter is still in
> `configuration.nix` — harmless, can be removed.)

## WORKING (live)
- **Hyprland** (nixpkgs 0.55.x): Mocha theme, gradient/animated borders, rounding, blur, active/inactive
  opacity, bouncy pop-in + slide-fade animations. Scratchpad (`Super+S`), resize submap (`Super+R`+arrows),
  per-app window rules (block syntax).
- **Plugins** (nixpkgs `hyprlandPlugins`, ABI-matched, loaded at runtime):
  - **hyprbars** — per-window title bars.
  - **hyprspace** — workspace **overview** (`Alt+Tab` in the VM / `Super+Tab` on metal). Drag windows
    between the workspace thumbnails. This is the maintained replacement for the removed hyprexpo.
- **Quickshell bar** (`dotfiles/quickshell/shell.qml`): logo(→rofi) · live workspaces · MPRIS now-playing ·
  clock | CPU% + RAM% · audio · network · bluetooth · tray. **Animated control-centre popovers**
  (audio/network/bluetooth/system) with click-outside dismiss. Icons via `String.fromCharCode`.
- **Apps installed** (`home.packages`): **firefox, vscode, obsidian, claude-code** (CLI). In the VM's soft GL
  they may need `LIBGL_ALWAYS_SOFTWARE=1 firefox` / `code --disable-gpu` / `obsidian --disable-gpu`.
- **Terminals**: Ghostty (default, `LIBGL_ALWAYS_SOFTWARE=1`), **foot** fallback (`Super+Shift+Return`).
- **Launcher**: rofi (`Super+D`). **Notifications**: swaync (`Super+N`). **Lock/idle**: hyprlock (`Super+L`) + hypridle.
- **Greeter**: **tuigreet** (TTY — renders in the VM) on logout; boot is autologin. ReGreet is wired but **metal-only** (see below).
- **Theming**: Catppuccin Mocha everywhere; JetBrainsMono Nerd Font; Bibata cursor (`home.pointerCursor`).
- **CLI rice**: starship, fastfetch, zellij, lazygit, **LazyVim**, eza/bat, btop.
- **Wallpaper**: Mocha radial-gradient PNG (Nix/imagemagick) via **swaybg**.
- **Screen shader**: `glow.frag` — a **per-pixel** colour grade (vibrance + contrast + highlight self-glow +
  vignette). Damage-safe, no ghosting. (The old neighbour-sampling bloom was scrapped — see gotcha.)

## Metal-only (ready, but off in the VM)
Flip these on when the config moves to real hardware (Fedora):
- **ReGreet** (graphical GTK4 greeter): `programs.regreet.enable = true` in `configuration.nix`. Off in the VM
  because (a) GTK4 won't render under the VM's GL, and (b) its default Cantarell font fails to build on aarch64.
  A `lib.mkIf` hands `greetd`'s `default_session` from tuigreet over to ReGreet automatically when enabled.
- **Real bloom/halation shader** (`bloom.frag`): a dense 13×13 Gaussian halo. Too heavy for the VM's software GL,
  and it needs full-screen redraws. To switch (all in `hyprland.conf`, then `hyprctl reload`): point
  `decoration:screen_shader` at `bloom.frag` **and** uncomment the `debug { damage_tracking = 0 }` block.
- **Plymouth** boot splash: enabled + `virtio_gpu` in initrd, but not visible in the VM (fast/virtual display).

## Hard-won gotchas (do not relearn)
- **Mac→VM keyboard: UTM maps ⌘ (Cmd) → Super.** So every `Super+<letter>` WM bind **shadows the app's
  `Cmd+<letter>`** (e.g. `Super+S` scratchpad vs Cmd+S save, `Super+F` fullscreen vs Cmd+F find). AND macOS
  **grabs some Cmd combos before the VM** — `Cmd+Tab` (app switcher), `Cmd+grave`, `Cmd+Space` (Spotlight) —
  so those keys never reach Hyprland. Fix: use `Alt`(Option)+ combos for clashing WM binds (e.g. overview is
  `Alt+Tab`). This is a VM artifact; on metal Super isn't a Mac key, so it all disappears.
- **Hyprland plugins must be ABI-matched to the running Hyprland**, and they **load at runtime** via
  `hyprctl plugin load` (our `~/.config/hypr/load-plugins.sh`, run by `exec-once`). Consequences: use nixpkgs
  plugins with nixpkgs Hyprland (not a mismatched build); and **they only load on session start** — after a
  rebuild, reboot / re-login (or run the loader by hand) or `hyprctl plugin list` stays empty.
- **Official `hyprland-plugins` dropped hyprexpo + hyprtrails** (unmaintained, gone since v0.55). nixpkgs
  `hyprlandPlugins` has the maintained set: `hyprbars`, `hyprspace` (overview), `hyprfocus`, `hy3`, `hyprgrass`, …
- **ReGreet drags in `cantarell-fonts`** (its default font) via `fonts.packages`, and cantarell-fonts fails to
  build on aarch64 → it blocks the whole system build. Gate ReGreet to metal; use tuigreet in the VM.
- **Screen shaders that sample NEIGHBOURING pixels fight Hyprland's damage tracking** (it only redraws changed
  regions) → stale ghost/mesh artefacts, plus a single screen shader can't do real multi-pass bloom. Per-pixel
  shaders are damage-safe. Real bloom needs `debug:damage_tracking = 0` (full redraws — heavy). Hence glow.frag
  (VM) vs bloom.frag (metal).
- **home-manager file→dir (or pre-existing) collisions** abort activation ("would be clobbered"). Set
  `home-manager.backupFileExtension` so they get moved aside instead (now set to `hm-bak`).
- **VM GL is GLES-only for the compositor.** Client desktop-GL apps struggle: kitty segfaults; ghostty needs
  `LIBGL_ALWAYS_SOFTWARE=1`; Electron/Firefox may need software GL; hyprpaper/hyprlock/ReGreet may not render.
  foot/swaybg (CPU) and wlroots-GLES compositor plugins are reliable.
- **Qt needs `QT_QPA_PLATFORM=wayland`** (set in hyprland.conf `env`) or the Quickshell bar is blank.
- **`hyprland.conf` must be a read-only store copy, never a writable symlink** — Hyprland autogenerates a
  default config through a writable symlink and clobbers the repo file (and don't `rm` it while Hyprland runs).
- **Non-ASCII / Nerd-Font glyphs get stripped when written here** — use `String.fromCharCode(0xXXXX)` in QML.
- **Hyprland config is version-fast:** `windowrulev2`→`windowrule` block syntax (needs a `name`),
  `pseudotile` gone, shaders must be `#version 300 es`, `# hyprlang noerror true/false` suppresses
  config-error banners for plugin config that's parsed before the plugin loads. `tuigreet` is `pkgs.tuigreet`.
- **git sync in VM:** `git pull`; if it errors, `git fetch && git reset --hard origin/master`, then restore
  `hosts/vm/hardware.nix` from `~/hw-real.nix`.

## Docs in repo
- `docs/status.md` — this file (current state).
- `docs/walkthrough.md` — the annotated install journey.
- `docs/ricing-possibilities.md` — the roadmap/checklist of what's riced and what's fair game.
