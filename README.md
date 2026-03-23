# rog-helper

G-Helper for Linux. Interactive TUI for ASUS ROG laptop management.

## Features

- **Dashboard**: Live monitoring (temps, fans, power)
- **GPU**: Mode switching (Integrated/Hybrid/Vfio)
- **Fans**: Toggle custom fan curves vs firmware auto
- **Profiles**: Performance modes (Silent/Balanced/Turbo)
- **Battery**: Charge limits (20-100%)
- **Keyboard**: Backlight effects
- **Panel**: Overdrive toggle

## Requirements

- ASUS ROG laptop
- [asusctl](https://gitlab.com/asus-linux/asusctl)
- [supergfxctl](https://gitlab.com/asus-linux/supergfxctl)

## Usage

```bash
bundle install
bundle exec ruby bin/rog-helper
```

## Navigation

Btop-style dashboard: all panels visible; **focus** moves between them.

| Key | Action |
|-----|--------|
| Tab / Shift+Tab, ←/→, h/l | Next/previous panel |
| ↑/↓ or j/k | Adjust inside focused panel |
| Enter | Apply (where applicable) |
| q | Quit |
