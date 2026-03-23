# rog-helper TUI Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an interactive TUI wrapping asusctl and supergfxctl for ASUS ROG laptop management on Linux.

**Architecture:** Tab-based Bubbletea app. Each tab is a separate model. Command wrappers abstract CLI interactions. System info reader provides live monitoring data.

**Tech Stack:** Ruby 3.2+, bubbletea, lipgloss, bubbles

---

## Chunk 1: Project Setup + Command Wrappers

### Task 1: Initialize project and dependencies

**Files:**
- Create: `Gemfile`
- Create: `bin/rog-helper`
- Create: `lib/rog_helper.rb`

- [ ] **Step 1: Create Gemfile**

```ruby
# Gemfile
source "https://rubygems.org"

gem "bubbletea"
gem "lipgloss"
gem "bubbles"
```

- [ ] **Step 2: Create main entry point**

```ruby
#!/usr/bin/env ruby
# bin/rog-helper

require_relative "../lib/rog_helper"

RogHelper::App.run
```

- [ ] **Step 3: Create lib/rog_helper.rb**

```ruby
# lib/rog_helper.rb

require "bubbletea"
require "lipgloss"
require "bubbles"

module RogHelper
end

require_relative "rog_helper/commands/asusctl"
require_relative "rog_helper/commands/supergfxctl"
require_relative "rog_helper/system_info"
require_relative "rog_helper/styles"
require_relative "rog_helper/models/dashboard"
require_relative "rog_helper/models/gpu"
require_relative "rog_helper/models/fans"
require_relative "rog_helper/models/profiles"
require_relative "rog_helper/models/battery"
require_relative "rog_helper/models/keyboard"
require_relative "rog_helper/models/panel"
require_relative "rog_helper/app"
```

- [ ] **Step 4: Make bin/rog-helper executable**

Run: `chmod +x bin/rog-helper`

- [ ] **Step 5: Install dependencies**

Run: `bundle install`

- [ ] **Step 6: Commit**

```bash
git add Gemfile Gemfile.lock bin/ lib/rog_helper.rb
git commit -m "feat: initialize rog-helper project with dependencies"
```

---

### Task 2: Create asusctl command wrapper

**Files:**
- Create: `lib/rog_helper/commands/asusctl.rb`

- [ ] **Step 1: Create asusctl wrapper**

```ruby
# lib/rog_helper/commands/asusctl.rb

module RogHelper
  module Commands
    module Asusctl
      module_function

      def available?
        system("which asusctl > /dev/null 2>&1")
      end

      # Profiles
      def current_profile
        result = `asusctl profile get 2>/dev/null`
        result.match(/Active profile is (\w+)/)&.captures&.first
      end

      def list_profiles
        result = `asusctl profile list 2>/dev/null`
        result.lines.map { |l| l.strip }.reject(&:empty?)
      end

      def set_profile(name)
        system("asusctl profile set #{name}")
      end

      # Fan curves
      def fan_curves_enabled?
        result = `asusctl fan-curve --get-enabled 2>/dev/null`
        result.include?("true")
      end

      def fan_curve_data(profile)
        result = `asusctl fan-curve --mod-profile #{profile} 2>/dev/null`
        result.strip
      end

      def set_fan_curve(profile:, fan:, data:)
        system("asusctl fan-curve --mod-profile #{profile} --fan #{fan} --data '#{data}'")
      end

      def enable_fan_curves(enabled)
        system("asusctl fan-curve --enable-fan-curves #{enabled}")
      end

      def reset_fan_curve(profile)
        system("asusctl fan-curve --default --mod-profile #{profile}")
      end

      # Battery
      def battery_limit
        result = `asusctl battery info 2>/dev/null`
        result.match(/(\d+)%/)&.captures&.first&.to_i
      end

      def set_battery_limit(percent)
        system("asusctl battery limit #{percent}")
      end

      def battery_oneshot(percent = nil)
        cmd = "asusctl battery oneshot"
        cmd += " #{percent}" if percent
        system(cmd)
      end

      # Panel
      def panel_overdrive
        result = `asusctl armoury get panel_overdrive 2>/dev/null`
        result.include?("(1)")
      end

      def set_panel_overdrive(enabled)
        value = enabled ? "1" : "0"
        system("asusctl armoury set panel_overdrive #{value}")
      end

      # Keyboard backlight
      def aura_effects
        result = `asusctl aura effect --help 2>/dev/null`
        # Parse available effects
        result.scan(/(\w+)\s/).flatten
      end

      def set_aura_effect(effect)
        system("asusctl aura effect #{effect}")
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/commands/asusctl.rb
git commit -m "feat: add asusctl command wrapper"
```

---

### Task 3: Create supergfxctl command wrapper

**Files:**
- Create: `lib/rog_helper/commands/supergfxctl.rb`

- [ ] **Step 1: Create supergfxctl wrapper**

```ruby
# lib/rog_helper/commands/supergfxctl.rb

module RogHelper
  module Commands
    module Supergfxctl
      module_function

      def available?
        system("which supergfxctl > /dev/null 2>&1")
      end

      def current_mode
        `supergfxctl --get 2>/dev/null`.strip
      end

      def status
        `supergfxctl --status 2>/dev/null`.strip
      end

      def supported_modes
        result = `supergfxctl --supported 2>/dev/null`
        result.scan(/\[(\w+(?:,\s*\w+)*)\]/).flatten.flat_map { |s| s.split(", ").map(&:strip) }
      end

      def set_mode(mode)
        system("supergfxctl --mode #{mode}")
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/commands/supergfxctl.rb
git commit -m "feat: add supergfxctl command wrapper"
```

---

### Task 4: Create system info reader

**Files:**
- Create: `lib/rog_helper/system_info.rb`

- [ ] **Step 1: Create system info reader**

```ruby
# lib/rog_helper/system_info.rb

module RogHelper
  module SystemInfo
    module_function

    def cpu_temp
      # Try common hwmon paths
      paths = Dir.glob("/sys/class/hwmon/hwmon*/temp1_input")
      paths.each do |path|
        temp = File.read(path).strip.to_i / 1000.0
        return temp if temp > 0
      rescue
        next
      end
      nil
    end

    def gpu_temp
      if File.exist?("/usr/bin/nvidia-smi")
        result = `nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null`
        result.strip.to_i
      else
        # Try AMD GPU temp
        paths = Dir.glob("/sys/class/hwmon/hwmon*/temp1_input")
        paths.each do |path|
          temp = File.read(path).strip.to_i / 1000.0
          return temp if temp > 0
        rescue
          next
        end
        nil
      end
    end

    def fan_rpm(fan_type = :cpu)
      # Map fan type to hwmon paths
      hwmon_dirs = Dir.glob("/sys/class/hwmon/hwmon*")
      hwmon_dirs.each do |dir|
        name = File.read("#{dir}/name").strip rescue next
        
        case fan_type
        when :cpu
          if name.include?("asus") || name.include?("k10temp")
            rpm = File.read("#{dir}/fan1_input").strip.to_i rescue 0
            return rpm if rpm > 0
          end
        when :gpu
          if name.include?("nvidia") || name.include?("amdgpu")
            rpm = File.read("#{dir}/fan1_input").strip.to_i rescue 0
            return rpm if rpm > 0
          end
        end
      end
      0
    end

    def power_draw
      # Battery discharge rate in microwatts
      path = "/sys/class/power_supply/BAT0/power_now"
      if File.exist?(path)
        File.read(path).strip.to_i / 1_000_000.0  # Convert to watts
      else
        nil
      end
    end

    def battery_percent
      path = "/sys/class/power_supply/BAT0/capacity"
      if File.exist?(path)
        File.read(path).strip.to_i
      else
        nil
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/system_info.rb
git commit -m "feat: add system info reader for temps, fans, power"
```

---

### Task 5: Create styles

**Files:**
- Create: `lib/rog_helper/styles.rb`

- [ ] **Step 1: Create styles module**

```ruby
# lib/rog_helper/styles.rb

module RogHelper
  module Styles
    module_function

    def title
      Lipgloss::Style.new
        .bold(true)
        .foreground("#7D56F4")
    end

    def tab_active
      Lipgloss::Style.new
        .bold(true)
        .foreground("#FFFFFF")
        .background("#7D56F4")
        .padding(0, 1)
    end

    def tab_inactive
      Lipgloss::Style.new
        .foreground("#888888")
        .padding(0, 1)
    end

    def selected
      Lipgloss::Style.new
        .foreground("#7D56F4")
        .bold(true)
    end

    def value
      Lipgloss::Style.new
        .foreground("#00FF00")
    end

    def warning
      Lipgloss::Style.new
        .foreground("#FFAA00")
    end

    def error
      Lipgloss::Style.new
        .foreground("#FF0000")
    end

    def label
      Lipgloss::Style.new
        .foreground("#AAAAAA")
    end

    def border
      Lipgloss::Style.new
        .border(:rounded)
        .border_foreground("#7D56F4")
        .padding(1, 2)
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/styles.rb
git commit -m "feat: add Lipgloss styles for TUI"
```

---

## Chunk 2: Tab Models (Part 1)

### Task 6: Create Dashboard model

**Files:**
- Create: `lib/rog_helper/models/dashboard.rb`

- [ ] **Step 1: Create Dashboard model**

```ruby
# lib/rog_helper/models/dashboard.rb

module RogHelper
  module Models
    class Dashboard
      include Bubbletea::Model

      def initialize
        @cpu_temp = 0
        @gpu_temp = 0
        @fan_rpm = 0
        @power_draw = 0
        @gpu_mode = "Unknown"
        @profile = "Unknown"
        @spinner = Bubbles::Spinner.new
      end

      def init
        [self, @spinner.tick]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "q", "ctrl+c"
            return [self, Bubbletea.quit]
          end
        when :tick
          refresh_stats
          return [self, Bubbletea.tick(1, :tick)]
        end

        @spinner, command = @spinner.update(message)
        [self, command]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value

        content = <<~TEXT
          #{title_style.render("System Dashboard")}

          #{label_style.render("CPU Temp:")}     #{value_style.render("#{@cpu_temp}°C")}
          #{label_style.render("GPU Temp:")}     #{value_style.render("#{@gpu_temp}°C")}
          #{label_style.render("Fan RPM:")}      #{value_style.render("#{@fan_rpm} RPM")}
          #{label_style.render("Power Draw:")}   #{value_style.render("#{@power_draw}W")}
          #{label_style.render("GPU Mode:")}     #{value_style.render(@gpu_mode)}
          #{label_style.render("Profile:")}      #{value_style.render(@profile)}

          #{@spinner.view} Refreshing...
        TEXT

        border_style.render(content)
      end

      private

      def refresh_stats
        @cpu_temp = SystemInfo.cpu_temp&.round(1) || 0
        @gpu_temp = SystemInfo.gpu_temp&.round(1) || 0
        @fan_rpm = SystemInfo.fan_rpm(:cpu)
        @power_draw = SystemInfo.power_draw&.round(1) || 0
        @gpu_mode = Commands::Supergfxctl.current_mode rescue "Unknown"
        @profile = Commands::Asusctl.current_profile rescue "Unknown"
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/models/dashboard.rb
git commit -m "feat: add Dashboard model for live monitoring"
```

---

### Task 7: Create GPU model

**Files:**
- Create: `lib/rog_helper/models/gpu.rb`

- [ ] **Step 1: Create GPU model**

```ruby
# lib/rog_helper/models/gpu.rb

module RogHelper
  module Models
    class Gpu
      include Bubbletea::Model

      MODES = ["Integrated", "Hybrid", "Vfio"].freeze

      def initialize
        @current_mode = "Hybrid"
        @status = "Unknown"
        @selected_index = 0
        @modes = MODES
        refresh
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "up", "k"
            @selected_index = (@selected_index - 1) % @modes.length
          when "down", "j"
            @selected_index = (@selected_index + 1) % @modes.length
          when "enter"
            set_mode(@modes[@selected_index])
          when "r"
            refresh
          end
        end

        [self, nil]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value
        selected_style = Styles.selected

        mode_list = @modes.each_with_index.map do |mode, i|
          prefix = i == @selected_index ? "→ " : "  "
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{mode}")
        end

        content = <<~TEXT
          #{title_style.render("GPU Mode")}

          #{label_style.render("Current:")}  #{value_style.render(@current_mode)}
          #{label_style.render("Status:")}   #{value_style.render(@status)}

          #{label_style.render("Available modes:")}
          #{mode_list.join("\n")}

          #{label_style.render("[Enter] to select  [r] to refresh")}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @current_mode = Commands::Supergfxctl.current_mode rescue "Unknown"
        @status = Commands::Supergfxctl.status rescue "Unknown"
        @selected_index = @modes.index(@current_mode) || 0
      end

      def set_mode(mode)
        Commands::Supergfxctl.set_mode(mode)
        refresh
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/models/gpu.rb
git commit -m "feat: add GPU model for mode switching"
```

---

## Chunk 3: Tab Models (Part 2)

### Task 8: Create Profiles model

**Files:**
- Create: `lib/rog_helper/models/profiles.rb`

- [ ] **Step 1: Create Profiles model**

```ruby
# lib/rog_helper/models/profiles.rb

module RogHelper
  module Models
    class Profiles
      include Bubbletea::Model

      def initialize
        @profiles = ["Silent", "Balanced", "Turbo"]
        @current_profile = "Balanced"
        @selected_index = 1
        refresh
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "up", "k"
            @selected_index = (@selected_index - 1) % @profiles.length
          when "down", "j"
            @selected_index = (@selected_index + 1) % @profiles.length
          when "enter"
            set_profile(@profiles[@selected_index])
          when "r"
            refresh
          end
        end

        [self, nil]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value
        selected_style = Styles.selected

        profile_list = @profiles.each_with_index.map do |profile, i|
          prefix = i == @selected_index ? "→ " : "  "
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{profile}")
        end

        content = <<~TEXT
          #{title_style.render("Performance Profile")}

          #{label_style.render("Current:")}  #{value_style.render(@current_profile)}

          #{label_style.render("Available profiles:")}
          #{profile_list.join("\n")}

          #{label_style.render("[Enter] to select  [r] to refresh")}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @current_profile = Commands::Asusctl.current_profile rescue "Unknown"
        @selected_index = @profiles.index(@current_profile) || 1
      end

      def set_profile(profile)
        Commands::Asusctl.set_profile(profile)
        refresh
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/models/profiles.rb
git commit -m "feat: add Profiles model for performance modes"
```

---

### Task 9: Create Battery model

**Files:**
- Create: `lib/rog_helper/models/battery.rb`

- [ ] **Step 1: Create Battery model**

```ruby
# lib/rog_helper/models/battery.rb

module RogHelper
  module Models
    class Battery
      include Bubbletea::Model

      LIMITS = (20..100).step(5).to_a.freeze

      def initialize
        @current_limit = 100
        @selected_index = LIMITS.index(80) || 12
        refresh
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "up", "k"
            @selected_index = (@selected_index - 1) % LIMITS.length
          when "down", "j"
            @selected_index = (@selected_index + 1) % LIMITS.length
          when "enter"
            set_limit(LIMITS[@selected_index])
          when "o"
            oneshot
          when "r"
            refresh
          end
        end

        [self, nil]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value
        selected_style = Styles.selected

        limit_list = LIMITS.each_with_index.map do |limit, i|
          prefix = i == @selected_index ? "→ " : "  "
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{limit}%")
        end

        content = <<~TEXT
          #{title_style.render("Battery Settings")}

          #{label_style.render("Current Limit:")}  #{value_style.render("#{@current_limit}%")}

          #{label_style.render("Set charge limit:")}
          #{limit_list.join("\n")}

          #{label_style.render("[Enter] to set limit  [o] for one-shot 100%  [r] to refresh")}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        limit = Commands::Asusctl.battery_limit rescue 100
        @current_limit = limit || 100
        @selected_index = LIMITS.index(@current_limit) || 12
      end

      def set_limit(percent)
        Commands::Asusctl.set_battery_limit(percent)
        refresh
      end

      def oneshot
        Commands::Asusctl.battery_oneshot
        refresh
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/models/battery.rb
git commit -m "feat: add Battery model for charge limits"
```

---

## Chunk 4: Tab Models (Part 3)

### Task 10: Create Fans model

**Files:**
- Create: `lib/rog_helper/models/fans.rb`

- [ ] **Step 1: Create Fans model**

```ruby
# lib/rog_helper/models/fans.rb

module RogHelper
  module Models
    class Fans
      include Bubbletea::Model

      def initialize
        @enabled = false
        @profiles = ["Silent", "Balanced", "Turbo"]
        @current_profile = "Balanced"
        @selected_profile = 1
        refresh
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "up", "k"
            @selected_profile = (@selected_profile - 1) % @profiles.length
          when "down", "j"
            @selected_profile = (@selected_profile + 1) % @profiles.length
          when "enter"
            toggle_fan_curves
          when "r"
            refresh
          end
        end

        [self, nil]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value
        selected_style = Styles.selected
        warning_style = Styles.warning

        status = @enabled ? value_style.render("Enabled") : warning_style.render("Disabled")

        profile_list = @profiles.each_with_index.map do |profile, i|
          prefix = i == @selected_profile ? "→ " : "  "
          style = i == @selected_profile ? selected_style : label_style
          style.render("#{prefix}#{profile}")
        end

        content = <<~TEXT
          #{title_style.render("Fan Curves")}

          #{label_style.render("Status:")}  #{status}
          #{label_style.render("Profile:")} #{value_style.render(@current_profile)}

          #{label_style.render("Select profile to configure:")}
          #{profile_list.join("\n")}

          #{label_style.render("[Enter] to toggle  [r] to refresh")}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @enabled = Commands::Asusctl.fan_curves_enabled? rescue false
        @current_profile = Commands::Asusctl.current_profile rescue "Balanced"
        @selected_profile = @profiles.index(@current_profile) || 1
      end

      def toggle_fan_curves
        Commands::Asusctl.enable_fan_curves(!@enabled)
        refresh
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/models/fans.rb
git commit -m "feat: add Fans model for fan curve control"
```

---

### Task 11: Create Keyboard model

**Files:**
- Create: `lib/rog_helper/models/keyboard.rb`

- [ ] **Step 1: Create Keyboard model**

```ruby
# lib/rog_helper/models/keyboard.rb

module RogHelper
  module Models
    class Keyboard
      include Bubbletea::Model

      # Common ASUS Aura effects
      EFFECTS = %w[
        static breathe rainbow pulse comet
        flash dash adaptive
      ].freeze

      def initialize
        @effects = EFFECTS
        @selected_index = 0
        @current_effect = "static"
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "up", "k"
            @selected_index = (@selected_index - 1) % @effects.length
          when "down", "j"
            @selected_index = (@selected_index + 1) % @effects.length
          when "enter"
            set_effect(@effects[@selected_index])
          end
        end

        [self, nil]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value
        selected_style = Styles.selected

        effect_list = @effects.each_with_index.map do |effect, i|
          prefix = i == @selected_index ? "→ " : "  "
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{effect.capitalize}")
        end

        content = <<~TEXT
          #{title_style.render("Keyboard Backlight")}

          #{label_style.render("Current Effect:")}  #{value_style.render(@current_effect.capitalize)}

          #{label_style.render("Available effects:")}
          #{effect_list.join("\n")}

          #{label_style.render("[Enter] to select")}
        TEXT

        border_style.render(content)
      end

      private

      def set_effect(effect)
        Commands::Asusctl.set_aura_effect(effect)
        @current_effect = effect
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/models/keyboard.rb
git commit -m "feat: add Keyboard model for backlight effects"
```

---

### Task 12: Create Panel model

**Files:**
- Create: `lib/rog_helper/models/panel.rb`

- [ ] **Step 1: Create Panel model**

```ruby
# lib/rog_helper/models/panel.rb

module RogHelper
  module Models
    class Panel
      include Bubbletea::Model

      def initialize
        @overdrive = false
        refresh
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when "enter"
            toggle_overdrive
          when "r"
            refresh
          end
        end

        [self, nil]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value
        warning_style = Styles.warning

        status = @overdrive ? value_style.render("Enabled") : warning_style.render("Disabled")

        content = <<~TEXT
          #{title_style.render("Panel Settings")}

          #{label_style.render("Overdrive:")}  #{status}

          #{label_style.render("[Enter] to toggle  [r] to refresh")}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @overdrive = Commands::Asusctl.panel_overdrive rescue false
      end

      def toggle_overdrive
        Commands::Asusctl.set_panel_overdrive(!@overdrive)
        refresh
      end
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/models/panel.rb
git commit -m "feat: add Panel model for overdrive toggle"
```

---

## Chunk 5: Main App + Integration

### Task 13: Create main App with tab navigation

**Files:**
- Create: `lib/rog_helper/app.rb`

- [ ] **Step 1: Create App model**

```ruby
# lib/rog_helper/app.rb

module RogHelper
  class App
    include Bubbletea::Model

    TABS = [
      { name: "Dashboard", model: Models::Dashboard },
      { name: "GPU", model: Models::Gpu },
      { name: "Fans", model: Models::Fans },
      { name: "Profiles", model: Models::Profiles },
      { name: "Battery", model: Models::Battery },
      { name: "Keyboard", model: Models::Keyboard },
      { name: "Panel", model: Models::Panel }
    ].freeze

    def initialize
      @current_tab = 0
      @models = TABS.map { |tab| tab[:model].new }
    end

    def init
      [self, Bubbletea.tick(1, :tick)]
    end

    def update(message)
      case message
      when Bubbletea::KeyMessage
        case message.to_s
        when "q", "ctrl+c"
          return [self, Bubbletea.quit]
        when "tab", "right", "l"
          @current_tab = (@current_tab + 1) % TABS.length
        when "shift+tab", "left", "h"
          @current_tab = (@current_tab - 1) % TABS.length
        end
      when :tick
        # Pass tick to dashboard for live updates
        @models[0], _ = @models[0].update(:tick)
        return [self, Bubbletea.tick(1, :tick)]
      end

      # Delegate to current tab model
      @models[@current_tab], command = @models[@current_tab].update(message)
      [self, command]
    end

    def view
      title_style = Styles.title
      tab_active_style = Styles.tab_active
      tab_inactive_style = Styles.tab_inactive

      # Build tab bar
      tabs = TABS.each_with_index.map do |tab, i|
        if i == @current_tab
          tab_active_style.render(tab[:name])
        else
          tab_inactive_style.render(tab[:name])
        end
      end

      header = "  rog-helper  "
      tab_bar = tabs.join(" │ ")

      <<~TEXT
        #{title_style.render(header)}
        #{tab_bar}
        #{"─" * 50}

        #{@models[@current_tab].view}

        #{tab_inactive_style.render("  [Tab] next  [Shift+Tab] prev  [q] quit")}
      TEXT
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add lib/rog_helper/app.rb
git commit -m "feat: add main App with tab navigation"
```

---

### Task 14: Test and finalize

**Files:**
- None (testing only)

- [ ] **Step 1: Run the app**

Run: `bundle exec ruby bin/rog-helper`

- [ ] **Step 2: Test each tab**

- Navigate through all tabs with Tab/Shift+Tab
- Test GPU mode switching
- Test profile switching
- Test battery limit setting
- Verify Dashboard live updates

- [ ] **Step 3: Create README**

```markdown
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
```

- [ ] **Step 4: Final commit**

```bash
git add README.md
git commit -m "docs: add README with usage instructions"
```

---

## Summary

**Total Tasks:** 14
**Estimated Time:** 45-60 minutes

**Key Architecture Decisions:**
1. Each tab is a separate Bubbletea Model
2. Command wrappers abstract CLI interactions
3. System info reader provides live monitoring data
4. No custom persistence — daemons handle it
5. Simple Tab-based navigation like G-Helper
