# rog-helper

G-Helper for Linux. Interactive TUI for ASUS ROG laptop management.

## Features

- **Dashboard**: Live monitoring (temps, fans, power)
- **GPU**: Mode switching (Integrated/Hybrid/Vfio)
- **Fans**: Fan curve control per profile
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

| Key | Action |
|-----|--------|
| Tab / → | Next tab |
| Shift+Tab / ← | Previous tab |
| ↑/↓ | Navigate items |
| Enter | Select/apply |
| q | Quit |
