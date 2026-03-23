# rog-helper TUI Design Spec

## Overview

Interactive terminal app wrapping `asusctl` + `supergfxctl`. G-Helper equivalent for Linux ASUS ROG laptops.

## Stack

- **bubbletea** — TUI framework (Elm architecture)
- **lipgloss** — styling and layout
- **bubbles** — components (spinner, progress bars)
- Ruby 3.2+

## Project Structure

```
~/code/itsameandrea/
├── Gemfile
├── bin/rog-helper
├── lib/
│   ├── rog_helper/
│   │   ├── app.rb              # Main Bubbletea app (dashboard layout)
│   │   ├── models/
│   │   │   ├── dashboard.rb    # Live monitoring
│   │   │   ├── gpu.rb          # GPU mode switching
│   │   │   ├── fans.rb         # Fan curves
│   │   │   ├── profiles.rb     # Performance profiles
│   │   │   ├── battery.rb      # Battery settings
│   │   │   ├── keyboard.rb     # Keyboard backlight
│   │   │   └── panel.rb        # Panel overdrive
│   │   ├── commands/
│   │   │   ├── asusctl.rb      # Wrapper around asusctl CLI
│   │   │   └── supergfxctl.rb  # Wrapper around supergfxctl CLI
│   │   └── system_info.rb      # Reading temps, fan RPM, power
│   └── rog_helper.rb
└── spec/
```

## Layout (btop-style dashboard)

Single full-screen grid of bordered panels (like `btop`), not separate tab pages. Focus moves between panels; all sections stay visible.

### CPU
- Live: temp bar, fan RPM, power draw (tick every 1s)

### GPU
- Modes from `supergfxctl --supported`; selection with arrows/j-k, `Enter` runs `supergfxctl --mode`

### Fans
- Shows custom curves vs firmware auto; `Enter` toggles curve enable

### Profile / Battery / Keyboard / Panel
- Same as before: profile list, charge limits, aura effect, panel overdrive (`asusctl` commands as in implementation)

## Navigation

| Key | Action |
|-----|--------|
| `Tab` / `Shift+Tab`, arrows, `h`/`l` | Move focus between panels |
| `↑`/`↓` or `j`/`k` | Adjust inside focused panel |
| `Enter` | Apply (GPU, profile, battery, keyboard, fan curves) |
| `q` or `Ctrl+C` | Quit |

Alternate screen (`alt_screen`) is used for a full-terminal btop-like session.

## Data Sources

| Data | Source |
|------|--------|
| GPU mode/status | `supergfxctl` commands |
| Profiles, fans, battery, keyboard, panel | `asusctl` commands |
| CPU/GPU temps | `/sys/class/hwmon/` |
| Fan RPM | `/sys/class/hwmon/` |
| Power draw | `/sys/class/power_supply/BAT0/power_now` |
| GPU stats | `nvidia-smi` (when available) |

## Persistence

Settings persistence is handled by the underlying daemons:
- `supergfxd` remembers GPU mode across reboots
- `asusd` remembers profiles, fan curves, battery limits

No custom persistence layer needed.

## Error Handling

- Graceful degradation: if a command fails, show error message in TUI
- Missing commands: detect if `asusctl` or `supergfxctl` not installed, show warning
- GPU not available: in Integrated mode, GPU panel shows powered-off state

## Success Criteria

1. App launches and displays the dashboard layout
2. Can switch GPU modes without logout
3. Can change profiles and see immediate effect
4. Dashboard updates live with temps, fans, power
5. All asusctl/supergfxctl features accessible
6. Clean error messages on failure
