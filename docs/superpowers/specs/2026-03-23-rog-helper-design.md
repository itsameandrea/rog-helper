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
│   │   ├── app.rb              # Main Bubbletea app (tab manager)
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

## Tabs

### 1. Dashboard (Live Monitoring)
- CPU/GPU temperatures
- Fan RPM (CPU/GPU/mid)
- Power draw (battery discharge rate)
- GPU mode indicator
- Active profile indicator
- Updates every 1 second

### 2. GPU
- Mode switching: Integrated / Hybrid / Vfio
- Current mode display
- Power status (on/off)
- Commands: `supergfxctl --mode X`, `supergfxctl --get`, `supergfxctl --status`

### 3. Fans
- Per-profile fan curves
- Per-fan: CPU, GPU, mid
- Enable/disable curves
- Edit curve points (temp:percentage format)
- Commands: `asusctl fan-curve --get-enabled`, `--mod-profile X --fan cpu --data ...`

### 4. Profiles
- Set active profile: Silent / Balanced / Turbo
- List available profiles
- Commands: `asusctl profile get`, `asusctl profile set X`, `asusctl profile list`

### 5. Battery
- Charge limit (20-100%)
- One-shot full charge
- Commands: `asusctl battery limit X`, `asusctl battery info`, `asusctl battery oneshot`

### 6. Keyboard
- Backlight effect selection
- Brightness control
- Power toggle
- Commands: `asusctl aura effect ...`, `asusctl leds ...`

### 7. Panel
- Overdrive toggle
- Commands: `asusctl armoury get panel_overdrive`, `asusctl armoury set panel_overdrive X`

## Navigation

| Key | Action |
|-----|--------|
| `←`/`→` or `Tab` | Switch tabs |
| `↑`/`↓` | Navigate within tab |
| `Enter` | Select/apply |
| `q` or `Ctrl+C` | Quit |

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
- GPU not available: in Integrated mode, GPU tab shows "GPU powered off"

## Success Criteria

1. App launches and displays tabbed interface
2. Can switch GPU modes without logout
3. Can change profiles and see immediate effect
4. Dashboard updates live with temps, fans, power
5. All asusctl/supergfxctl features accessible
6. Clean error messages on failure
