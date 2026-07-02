# Ricing possibilities & roadmap

The full surface area of what can be customised on a Hyprland/Wayland desktop, as a
checklist. `[x]` = already done in this repo · `[ ]` = fair game.

Two things to remember at the top: this catalogue is the **floor, not the ceiling** —
(1) anything custom-built in Quickshell/AGS has no catalogue entry, and (2) the *reactive*
layer (wiring the look to live system state) is where it becomes genuinely bottomless.

---

## 0. Boot & login (before the desktop)
- [ ] **Plymouth** — animated boot splash
- [ ] Bootloader theme (GRUB / rEFInd; systemd-boot is plain)
- [ ] Greeter: **ReGreet** / SDDM theme / styled **tuigreet**
- [x] Session autologin (greetd → Hyprland)

## 1. The compositor — Hyprland
- [x] Animations (bézier curves; window / fade / workspace)
- [x] Decoration: rounding, gradient borders, shadows, blur, active/inactive opacity
- [x] Layout: dwindle (BSP)
- [ ] Window rules: float/size/position/opacity/workspace per app
- [ ] Tabbed groups & scratchpads (special workspaces)
- [ ] Plugins (`hyprpm`): **hyprexpo** (workspace grid), **hyprbars** (title bars), **hyprtrails** (mouse trails), borders-plus-plus, scrolling layouts
- [ ] **Submaps** (modal, vim-like keybind layers); gestures (3-finger swipe); `keyd` remapping
- [ ] **hyprcursor** — animated, resolution-independent cursors
- [ ] Screen shaders (GLSL): vibrance, CRT, blue-light, film grain

## 2. The shell / bar / widgets
- Framework: **Quickshell** (QML, current), **waybar** (classic), **AGS/Astal** (JS/TS), **eww**, **fabric** (Python), nwg-shell
- [x] Bar: logo, live workspaces, clock, volume
- [ ] More bar modules: window title, **system tray**, battery, network, bluetooth, brightness, **now-playing (MPRIS + album art)**, CPU/RAM/temp, keyboard layout, updates, weather
- [ ] Panels/popups: **notification centre**, **control centre** (wifi/bt/volume/brightness sliders + toggles), **launcher**, **media widget**, **calendar**, **power menu**, **system monitor**, **OSDs** (volume/brightness), workspace overview, **dock**
- [ ] Desktop widgets: clock/date/weather overlays, conky-style system info, audio visualiser

## 3. Wallpaper
- [x] Static solid colour (swaybg)
- [ ] **awww** (animated, transitions, GIF), **mpvpaper** (video), shader wallpapers
- [ ] Per-workspace / per-monitor / time-of-day cycling; audio-reactive

## 4. Launcher & menus
- [x] **fuzzel** (themed)
- [ ] Alternatives: **rofi-wayland**, **anyrun**, **walker**, tofi, or Quickshell-custom
- [ ] Extra uses: calculator, emoji, **clipboard history** (cliphist), window switcher, power menu, ssh/file/dictionary search

## 5. Notifications
- [x] **mako** (themed)
- [ ] **swaync** (centre + history + DND + media), dunst, or Quickshell-custom

## 6. Lock / idle / power
- [ ] **hyprlock** (blur, clock, album art, widgets)
- [ ] **hypridle** (dim → lock → suspend timeouts)
- [ ] **wlogout** (power-menu grid)

## 7. Terminal & CLI
- [x] Terminal: **Ghostty** (default) + **foot** fallback, both themed
- [ ] Prompt: **starship** / oh-my-posh / powerlevel10k
- [ ] Shell: fish/zsh + plugins
- [ ] Ricey CLI tools: **btop**, **fastfetch** (logo art), **cava** (audio visualiser), **eza/bat/yazi**, **lazygit**, tmux/zellij themed status
- [ ] Terminal shaders (CRT/glow/retro — you have a `ghostty-shaders` folder)

## 8. Editor / dev workspace
- [ ] **Neovim**: colorscheme, **lualine**, dashboard, transparency, `noice.nvim`, which-key
- [ ] tmux/zellij themes, lazygit

## 9. Per-app theming (multiplies endlessly)
- [ ] **Spicetify** (Spotify), **Vencord**/BetterDiscord (Discord)
- [ ] **Firefox `userChrome.css`** (rice the browser UI — vertical tabs, hidden chrome), **Zen/Floorp**
- [ ] VSCode / Obsidian themes, **Stylus** (per-website CSS)

## 10. System-wide theming
- [x] Manual Catppuccin Mocha (foot/fuzzel/mako/hyprland/quickshell)
- [x] Nerd Font (JetBrains Mono)
- [ ] GTK/Qt themes (qt5ct/qt6ct, Kvantum), icon theme (Papirus/Tela), cursor theme (Bibata)
- [ ] **Stylix** (Nix) — ONE base16 palette auto-themes GTK, Qt, terminal, vim, bar, everything
- [ ] **Dynamic colour-from-wallpaper**: **matugen / wallust / pywal** — recolour the whole system to match the wallpaper
- [ ] Light/dark auto-switch (wlsunset by time); font ligatures & rendering tuning

## 11. Effects & motion
- [ ] Hyprland screen shaders, animated borders, mouse trails, blur layers
- [ ] Audio-reactive visuals (cava → bar / wallpaper / shader)
- [ ] Transitions on workspace/window change

## 12. The reactive / scripted layer (the deep end)
- [ ] Hyprland **`socket2` events** → run scripts on window/workspace/focus changes
- [ ] State-driven visuals (accent colour tracks battery / CPU / time-of-day)
- [ ] **Wallpaper → palette pipelines** (matugen recolours everything live on wallpaper change)
- [ ] Custom keybind macros; screenshot/clipboard workflows

## 13. Audio & hardware
- [ ] **EasyEffects** (EQ/effects, ricey UI); custom system sounds
- [ ] **OpenRGB** — sync keyboard/peripheral lighting to the palette (real hardware only)

## 14. Utilities / workflow tools
- [x] Screenshot: grim + slurp
- [ ] **hyprshot / grimblast / satty** (annotate) / swappy; **wf-recorder** / OBS (recording)
- [ ] **hyprpicker** (colour picker), **cliphist** (clipboard history), **wlsunset/gammastep** (night light), **bemoji**

## 15. Functional rice (workflow, not just looks)
- [ ] Scratchpads, quick-toggle panels
- [ ] Per-app window rules, auto-tiling logic
- [ ] Focus / DND automation, pomodoro / activity widgets

---

### The two bottomless dimensions
- **Custom-built components** — anything you can imagine in Quickshell/AGS (no catalogue).
- **Reactivity** — wiring the look to live system state so it feels *alive*, not static.
