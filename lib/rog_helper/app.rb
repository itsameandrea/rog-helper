# frozen_string_literal: true

module RogHelper
  class App
    include Bubbletea::Model

    FAN_CURVES = {
      'Silent' => {
        points: [[45, 12], [55, 18], [65, 30], [75, 50], [85, 71]]
      },
      'Balanced' => {
        points: [[45, 12], [55, 28], [65, 48], [75, 72], [85, 94]]
      },
      'Performance' => {
        points: [[45, 12], [52, 35], [60, 65], [70, 100], [80, 153]]
      }
    }.freeze

    def initialize
      @active = 0
      @width = terminal_width
      @height = terminal_height
      @cpu_temp = 0
      @cpu_power = nil
      @gpu_temp = nil
      @gpu_power = nil
      @fan_rpm = 0
      @power = 0
      @gpu_mode = 'Hybrid'
      @gpu_modes = %w[Integrated Hybrid AsusMuxDgpu]
      @gpu_idx = 1
      @fan_preset = 'Balanced'
      @fan_presets = FAN_CURVES.keys
      @fan_idx = 1
      @profile = ''
      @profiles = []
      @prof_idx = 0
      @bat_lim = 80
      @bat_lims = [60, 80, 100]
      @bat_idx = 1
      @kb_eff = 'static'
      @kb_effs = %w[static breathe rainbow pulse comet]
      @kb_idx = 0
      @slash_mode = 'Static'
      @slash_modes = %w[Off Static Bounce Flow Spectrum]
      @slash_idx = 0
      @power_state = SystemInfo.power_state
      SystemInfo.init_power_monitoring
      load_state
      apply_power_preferences
      refresh
    end

    def init
      [self, Bubbletea.tick(1) { :tick }]
    end

    def update(msg)
      case msg
      when Bubbletea::WindowSizeMessage
        @width = [msg.width, 120].max
        @height = msg.height
      when Bubbletea::KeyMessage
        case msg.to_s
        when 'q', 'ctrl+c' then return [self, Bubbletea.quit]
        when 'tab' then @active = (@active + 1) % 7
        when 'shift+tab' then @active = (@active - 1) % 7
        when 'right', 'l' then move(1)
        when 'left', 'h' then move(-1)
        when 'enter' then return apply
        end
      when :tick
        check_power_state_change
        refresh
        return [self, Bubbletea.tick(1) { :tick }]
      end
      [self, nil]
    end

    def view
      w = (@width - 3) / 2
      footer = "\e[3;38;5;245m Tab panels · ←/→ options · Enter apply · q quit\e[0m"

      row1 = hbox(w, ['System snapshot', cpu_body, 0], ['Battery charge limit', bat_body, 1])
      row2 = hbox(w, ['Performance profile', prof_body, 2], ['GPU settings', gpu_body, 3])
      row3 = hbox(w, ['Keyboard backlight', kb_body, 4], ['Slash control', slash_body, 5])
      fans = box('Fan profiles', fans_body, 6, terminal_width - 1, fans_height)

      [row1, row2, row3, fans, footer].join("\n")
    end

    private

    def terminal_width
      `tput cols 2>/dev/null`.to_i.then { |w| [w, 120].max }
    end

    def terminal_height
      `tput lines 2>/dev/null`.to_i.then { |h| [h, 24].max }
    end

    def fans_height
      fixed_layout_lines = 19
      available = @height - fixed_layout_lines
      [[available, 13].min, 1].max
    end

    def box(title, content, idx, width, height = 3)
      active = @active == idx
      bc = active ? '75' : '60'
      tc = active ? '75' : '245'

      tl = '╭'
      tr = '╮'
      bl = '╰'
      br = '╯'
      h = '─'
      v = '│'

      title_str = "\e[1;38;5;#{tc}m#{title}\e[0m"
      title_len = title.length
      left = h * 2
      right = h * (width - 4 - title_len)
      top = "\e[38;5;#{bc}m#{tl}#{left}#{title_str}\e[38;5;#{bc}m#{right}#{tr}\e[0m"

      content_lines = content.split("\n")
      content_lines << '' while content_lines.length < height
      padded = content_lines.map do |line|
        pad = width - 4 - visible_len(line)
        "\e[38;5;#{bc}m#{v}\e[0m #{line}#{' ' * [pad, 0].max} \e[38;5;#{bc}m#{v}\e[0m"
      end

      bottom = "\e[38;5;#{bc}m#{bl}#{h * (width - 2)}#{br}\e[0m"

      [top, *padded, bottom].join("\n")
    end

    def hbox(width, left, right)
      l = box(left[0], left[1], left[2], width)
      r = box(right[0], right[1], right[2], width)
      l_lines = l.split("\n")
      r_lines = r.split("\n")
      l_lines.zip(r_lines).map { |a, b| "#{a}#{b}" }.join("\n")
    end

    def visible_len(str)
      str.gsub(/\e\[[^m]*m/, '').length
    end

    def meter(value, width = 10)
      filled = (value.to_f / 100 * width).round
      filled = [filled, width].min
      color = gradient_color(value)
      "\e[38;5;#{color}m#{'■' * filled}\e[38;5;238m#{'■' * (width - filled)}\e[0m"
    end

    def gradient_color(pct)
      case pct
      when 0..60 then '75'
      when 61..80 then '214'
      else '210'
      end
    end

    def cpu_body
      bar = meter(@cpu_temp, 10)
      cpu_power_str = @cpu_power ? " #{@cpu_power}W" : ''
      gpu_temp_str = gpu_enabled? && @gpu_temp && @gpu_temp.positive? ? "#{@gpu_temp.round(1)}°C" : nil
      gpu_power_str = gpu_enabled? && @gpu_power ? " #{@gpu_power}W" : ''
      gpu_line = gpu_temp_str ? "GPU #{gpu_temp_str}#{gpu_power_str}" : nil

      [
        "CPU #{bar} #{@cpu_temp}°C#{cpu_power_str}",
        gpu_line,
        "Fan #{@fan_rpm} RPM"
      ].compact.join("\n")
    end

    def gpu_body
      @gpu_modes.map.with_index do |m, i|
        i == @gpu_idx ? "\e[1;38;5;75m▸#{m}\e[0m" : " #{m}"
      end.join(' ')
    end

    def fans_body
      charts = @fan_presets.each_with_index.map do |name, i|
        curve = FAN_CURVES[name]
        active = i == @fan_idx
        render_fan_chart_compact(name, curve, active)
      end

      max_lines = charts.map(&:length).max
      charts.each { |c| c << '' while c.length < max_lines }

      charts[0].zip(*charts[1..]).map { |row| row.join('    ') }.join("\n")
    end

    def render_fan_chart_compact(name, curve, active)
      points = curve[:points]
      chart_h = 10
      chart_w = 28

      temp_min = 40
      temp_max = 95
      fan_min = 0
      fan_max = 5500

      grid = Array.new(chart_h) { Array.new(chart_w, nil) }

      points.each do |temp, fan_val|
        rpm = (fan_val.to_f / 255 * fan_max).round
        x = ((temp - temp_min).to_f / (temp_max - temp_min) * (chart_w - 1)).round
        y = (chart_h - 1) - ((rpm - fan_min).to_f / (fan_max - fan_min) * (chart_h - 1)).round
        x = [[x, 0].max, chart_w - 1].min
        y = [[y, 0].max, chart_h - 1].min
        grid[y][x] = active ? "\e[38;5;117m●\e[0m" : "\e[38;5;242m●\e[0m"
      end

      sorted = points.sort_by(&:first)
      (0...sorted.length - 1).each do |i|
        rpm1 = (sorted[i][1].to_f / 255 * fan_max).round
        rpm2 = (sorted[i + 1][1].to_f / 255 * fan_max).round
        x1 = ((sorted[i][0] - temp_min).to_f / (temp_max - temp_min) * (chart_w - 1)).round
        x2 = ((sorted[i + 1][0] - temp_min).to_f / (temp_max - temp_min) * (chart_w - 1)).round
        y1 = (chart_h - 1) - ((rpm1 - fan_min).to_f / (fan_max - fan_min) * (chart_h - 1)).round
        y2 = (chart_h - 1) - ((rpm2 - fan_min).to_f / (fan_max - fan_min) * (chart_h - 1)).round

        draw_curve_line(grid, x1, y1, x2, y2, active)
      end

      lines = []

      title_text = active ? "▸#{name}" : " #{name}"
      title = active ? "\e[1;38;5;117m#{title_text}\e[0m" : "\e[38;5;245m#{title_text}\e[0m"
      title = "      #{title}#{' ' * (chart_w - visible_len(title))} "
      lines << title

      color = active ? '117' : '242'
      border = "\e[38;5;#{color}m│\e[0m"

      grid.each_with_index do |row, ri|
        rpm_label = case ri
                    when 0 then '5k'
                    when 2 then '4k'
                    when 4 then '3k'
                    when 6 then '2k'
                    when 8 then '1k'
                    when 9 then '0'
                    else ''
                    end.rjust(4)

        row_str = row.map { |c| c || "\e[38;5;238m·\e[0m" }.join
        lines << "#{rpm_label} #{border}#{row_str}#{border}"
      end

      bottom_border = "\e[38;5;#{color}m└#{'─' * chart_w}┘\e[0m"
      lines << "     #{bottom_border}"
      lines << "      40°C#{' ' * (chart_w - 8)}95°C "

      lines
    end

    def draw_curve_line(grid, x1, y1, x2, y2, active)
      dx = (x2 - x1).abs
      dy = (y2 - y1).abs

      if dx == 0
        (y1..y2).each { |y| grid[y][x1] ||= "\e[38;5;#{active ? 117 : 238}m·\e[0m" }
        (y2..y1).each { |y| grid[y][x1] ||= "\e[38;5;#{active ? 117 : 238}m·\e[0m" }
        return
      end

      if dy == 0
        (x1..x2).each { |x| grid[y1][x] ||= "\e[38;5;#{active ? 117 : 238}m·\e[0m" }
        (x2..x1).each { |x| grid[y1][x] ||= "\e[38;5;#{active ? 117 : 238}m·\e[0m" }
        return
      end

      if dx > dy
        y = y1.to_f
        step = dy.to_f / dx * (y2 > y1 ? 1 : -1)
        (x1..x2).each do |x|
          grid[y.round][x] ||= "\e[38;5;#{active ? 117 : 238}m·\e[0m"
          y += step
        end
      else
        x = x1.to_f
        step = dx.to_f / dy * (x2 > x1 ? 1 : -1)
        (y1..y2).each do |yy|
          grid[yy][x.round] ||= "\e[38;5;#{active ? 117 : 238}m·\e[0m"
          x += step
        end
        (y2..y1).each do |yy|
          grid[yy][x.round] ||= "\e[38;5;#{active ? 117 : 238}m·\e[0m"
          x -= step
        end
      end
    end

    def prof_body
      @profiles.map.with_index do |p, i|
        i == @prof_idx ? "\e[1;38;5;75m▸#{p}\e[0m" : " #{p}"
      end.join(' ')
    end

    def bat_body
      @bat_lims.map.with_index do |l, i|
        i == @bat_idx ? "\e[1;38;5;75m▸#{l}%\e[0m" : " #{l}%"
      end.join(' ')
    end

    def kb_body
      @kb_effs.map.with_index do |e, i|
        i == @kb_idx ? "\e[1;38;5;75m▸#{e.capitalize}\e[0m" : " #{e.capitalize}"
      end.join(' ')
    end

    def slash_body
      @slash_modes.map.with_index do |m, i|
        i == @slash_idx ? "\e[1;38;5;75m▸#{m}\e[0m" : " #{m}"
      end.join(' ')
    end

    def move(dir)
      case @active
      when 1 then @bat_idx = (@bat_idx + dir) % @bat_lims.length
      when 2 then @prof_idx = (@prof_idx + dir) % @profiles.length
      when 3 then @gpu_idx = (@gpu_idx + dir) % @gpu_modes.length
      when 4 then @kb_idx = (@kb_idx + dir) % @kb_effs.length
      when 5 then @slash_idx = (@slash_idx + dir) % @slash_modes.length
      when 6 then @fan_idx = (@fan_idx + dir) % @fan_presets.length
      end
    end

    def apply
      case @active
      when 1 then begin
        Commands::Asusctl.set_battery_limit(@bat_lims[@bat_idx])
      rescue StandardError
        nil
      end
      when 2
        profile = @profiles[@prof_idx]
        begin
          Commands::Asusctl.set_slash_enabled(false)
          Commands::Asusctl.set_profile(profile)
          @profile = profile
          save_power_preference(:profile, profile)
          restore_slash_state
        rescue StandardError
          nil
        end
      when 3
        mode = @gpu_modes[@gpu_idx]
        begin
          Commands::Supergfxctl.set_mode(mode)
          @gpu_mode = mode
          @gpu_idx = @gpu_modes.find_index { |m| m.to_s.casecmp(mode.to_s).zero? } || 0
          save_power_preference(:gpu_mode, mode)
          true
        rescue StandardError
          nil
        end
      when 4 then begin
        Commands::Asusctl.set_aura_effect(@kb_effs[@kb_idx])
      rescue StandardError
        nil
      end
      when 5 then begin
        mode = @slash_modes[@slash_idx]
        if mode == 'Off'
          Commands::Asusctl.set_slash_enabled(false)
        else
          Commands::Asusctl.set_slash_enabled(true)
          Commands::Asusctl.set_slash_mode(mode)
        end
        @slash_mode = mode
        save_power_preference(:slash_mode, mode)
      rescue StandardError
        nil
      end
      when 6
        @fan_preset = @fan_presets[@fan_idx]
        begin
          apply_fan_curve(@fan_preset)
          save_power_preference(:fan_preset, @fan_preset)
        rescue StandardError
          nil
        end
      end

      [self, nil]
    end

    def refresh
      @cpu_temp = SystemInfo.cpu_temp&.round(1) || 0
      @cpu_power = SystemInfo.cpu_power
      @gpu_temp = SystemInfo.gpu_temp
      @gpu_power = SystemInfo.gpu_power
      @fan_rpm = SystemInfo.fan_rpm(:cpu)
      @power = SystemInfo.power_draw&.round(1) || 0
    end

    def gpu_enabled?
      @gpu_mode.to_s.casecmp('Integrated') != 0
    end

    def load_state
      sup = begin
        Commands::Supergfxctl.supported_modes
      rescue StandardError
        []
      end
      @gpu_modes = sup.any? ? sup : @gpu_modes
      @gpu_idx = @gpu_modes.find_index { |m| m.to_s.casecmp(@gpu_mode.to_s).zero? } || 0

      @profile = begin
        Commands::Asusctl.current_profile
      rescue StandardError
        @profile
      end
      sys_profiles = begin
        Commands::Asusctl.list_profiles
      rescue StandardError
        []
      end
      @profiles = sys_profiles.any? ? sys_profiles : @profiles
      @prof_idx = @profiles.index(@profile) || 0

      @bat_lim = begin
        Commands::Asusctl.battery_limit
      rescue StandardError
        @bat_lim
      end
      @bat_idx = @bat_lims.index(@bat_lim) || 1

      sys_slash_modes = begin
        Commands::Asusctl.slash_modes
      rescue StandardError
        []
      end
      @slash_modes = compact_slash_modes(sys_slash_modes)
      @slash_idx = @slash_modes.index(@slash_mode) || 0

      @fan_idx = @fan_presets.index(@fan_preset) || 0
    end

    def compact_slash_modes(system_modes)
      preferred_modes = %w[Static Bounce Flow Spectrum]
      available = system_modes.uniq
      selected = preferred_modes.select { |mode| available.include?(mode) }
      selected = available.first(4) if selected.empty?
      selected += preferred_modes.reject { |mode| selected.include?(mode) }
      ['Off', *selected.first(4)]
    end

    def check_power_state_change
      current = SystemInfo.power_state
      return if current == @power_state

      @power_state = current
      apply_power_preferences
    end

    def apply_power_preferences
      return unless @power_state

      prefs = Preferences.for_state(@power_state)

      if prefs[:profile] && @profiles.include?(prefs[:profile])
        Commands::Asusctl.set_profile(prefs[:profile])
        @profile = prefs[:profile]
        @prof_idx = @profiles.index(prefs[:profile]) || 0
      end

      if prefs[:gpu_mode] && @gpu_modes.any? { |m| m.to_s.casecmp(prefs[:gpu_mode].to_s).zero? }
        Commands::Supergfxctl.set_mode(prefs[:gpu_mode])
        @gpu_mode = prefs[:gpu_mode]
        @gpu_idx = @gpu_modes.find_index { |m| m.to_s.casecmp(prefs[:gpu_mode].to_s).zero? } || 0
      end

      if prefs[:fan_preset] && @fan_presets.include?(prefs[:fan_preset])
        @fan_preset = prefs[:fan_preset]
        @fan_idx = @fan_presets.index(prefs[:fan_preset]) || 0
        apply_fan_curve(@fan_preset)
      end

      return unless prefs[:slash_mode] && @slash_modes.include?(prefs[:slash_mode])

      mode = prefs[:slash_mode]
      if mode == 'Off'
        Commands::Asusctl.set_slash_enabled(false)
      else
        Commands::Asusctl.set_slash_enabled(true)
        Commands::Asusctl.set_slash_mode(mode)
      end
      @slash_mode = mode
      @slash_idx = @slash_modes.index(mode) || 0
    end

    def apply_fan_curve(preset_name)
      points = FAN_CURVES[preset_name][:points]
      return unless points && @profile

      data = points.map { |temp, pwm| "#{temp}c:#{pwm}" }.join(',')
      Commands::Asusctl.set_fan_curve(profile: @profile, fan: 'cpu', data: data)
    end

    def save_power_preference(key, value)
      return unless @power_state

      case key
      when :profile then Preferences.save_for_state(@power_state, profile: value)
      when :gpu_mode then Preferences.save_for_state(@power_state, gpu_mode: value)
      when :fan_preset then Preferences.save_for_state(@power_state, fan_preset: value)
      when :slash_mode then Preferences.save_for_state(@power_state, slash_mode: value)
      end
    end

    def restore_slash_state
      if @slash_mode == 'Off'
        Commands::Asusctl.set_slash_enabled(false)
      else
        Commands::Asusctl.set_slash_enabled(true)
        Commands::Asusctl.set_slash_mode(@slash_mode)
      end
    end
  end
end
