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

## Experimental branch — "Editorial Paper" theme (PARKED, resume later)

A full warm-light restyle that swaps the Mocha look for khonsu-v2's **editorial-paper**
aesthetic: sharp corners, 1px hairline rules, a single rust accent, Playfair Display +
Noto Sans typography, and a flat surface (no glow shader, no shadows, calmer motion).
Inspired by `/Users/callum/Desktop/coding/khonsu-v2` (its `src/App.css` paper palette +
`design/khonsu.pen`).

> **Lives on branch `theme/editorial-paper` (commit `5aba9df`), NOT on master.** Master
> is still Mocha. This is parked — not yet verified in the VM (first boot pending).

### Palette (the reference)
| Role | Hex | Used for |
|------|-----|----------|
| base | `#f4f1e8` | desktop / window bg + wallpaper |
| surface | `#faf8f2` | bar, popups, launcher, cards |
| panel | `#ece7dd` | inputs, progress tracks, buttons (hover `#e2dccd`) |
| ink | `#1b1916` | primary text |
| muted | `#8b8475` | secondary text, bar icons |
| hairline | `#d9d2c5` | 1px rules/borders (window inactive border `#d0c8b8`) |
| **accent (rust)** | `#a35e3a` | focus, active, selection, cursor (pressed `#8a4e30`) |
| link / red / green / yellow | `#3a6ea5` / `#a3432f` / `#5f7040` / `#b0842f` | prompt + status accents |

**Terminal ANSI (warm light):** bg `#f4f1e8` · fg `#2a2620` · cursor `#a35e3a` ·
0–7 `#43403a #a3432f #5f7040 #9a7218 #3a6ea5 #8a5673 #3f7d75 #6b6456` ·
8–15 `#6b6456 #b6503a #6f8049 #b0842f #4a7fb0 #9a6683 #4a8f86 #3a352c`.

### Fonts (added in `configuration.nix`)
- **Playfair Display** (`google-fonts.override`) — clock, ¶ wordmark, hyprlock, popup titles
- **Noto Sans** (`noto-fonts`) — UI/body, launcher, notifications, bar values
- **Noto Serif CJK SC** (`noto-fonts-cjk-serif`) — the 一 二 三 四 workspace numerals
- JetBrainsMono Nerd Font — kept for the terminal + functional bar glyphs (icons)

### What changed (14 files)
- **`quickshell/shell.qml`** — floating glass bar → flush **paper masthead** with a hairline
  underline; ¶ pilcrow wordmark (→rofi); **一二三四 CJK numerals** with a rust underline on the
  focused workspace; Playfair clock (`dddd, d MMMM · HH:mm`); sharp 1px-hairline popups, rust accents.
- **`hypr/hyprland.conf`** — rounding `0`; border `1px` (rust active / `#d0c8b8` inactive); glow
  shader **off**; shadows **off**; opacity ~opaque; no-bounce `paper` bezier; hyprbars + hyprspace
  overview repainted to paper. (Shaders left in `shaders/` if we ever want the neon look back.)
- **`rofi` / `fuzzel`** — cream, sharp, hairline, rust selection, Noto Sans.
- **`swaync` / `mako`** — cream cards, sharp, hairline, rust urgent/close.
- **`hypr/hyprlock.conf`** — paper bg, Playfair clock, rust input outline.
- **`foot` / `ghostty`** — warm-light ANSI palette (ink on cream, rust cursor), opaque.
- **`starship.toml`** — rust dir / ochre branch / olive prompt.
- **`zellij`** → `catppuccin-latte`; **`nvim`** → `catppuccin-latte` (melange noted as a warmer swap).
- **`hosts/vm/configuration.nix`** — the three font packages above.
- **`home/callum.nix`** — wallpaper → warm-paper radial gradient (`#f6f3ec`→`#e7e1d3`).

### Rebuild vs hot-reload
- **Needs `nixos-rebuild switch`:** fonts (configuration.nix), wallpaper (home/callum.nix), and
  `hyprland.conf` (it's a read-only store copy). Everything else hot-reloads / picks up on next launch.

### Test loop (the branch bit us once — VM was on master, so `git pull` found nothing)
```sh
cd ~/ricing-test && git fetch origin && git checkout theme/editorial-paper
sudo nixos-rebuild switch --flake ~/ricing-test#vm
# then restart the session so quickshell + wallpaper reload:
Super+Shift+E      # logout → autologin   (or: reboot)
```
Back to Mocha: `git checkout master && sudo nixos-rebuild switch --flake ~/ricing-test#vm`.

### Open items when we resume
- [ ] **Verify at all** — never booted yet.
- [ ] Confirm `google-fonts.override { fonts = ["Playfair Display"]; }` builds on aarch64; if it
      errors on the family name, swap for plain `pkgs.google-fonts`.
- [ ] Confirm the **一二三四** render (family `Noto Serif CJK SC`) rather than tofu boxes.
- [ ] Decide: flush masthead vs the old floating-rounded bar.
- [ ] Try `melange` nvim colorscheme for a warmer paper feel.
- [ ] Later: a matching warm-**dark** variant (khonsu defines one) as a swappable palette.

## Docs in repo
- `docs/status.md` — this file (current state).
- `docs/walkthrough.md` — the annotated install journey.
- `docs/ricing-possibilities.md` — the roadmap/checklist of what's riced and what's fair game.
