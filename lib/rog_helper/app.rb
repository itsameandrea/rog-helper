# frozen_string_literal: true

module RogHelper
  class App
    include Bubbletea::Model

    PANES = %i[cpu gpu fans profile battery keyboard panel].freeze

    def initialize
      @active_pane = 0
      @term_width = 80
      @term_height = 24
      @cpu_temp = 0
      @gpu_temp = 0
      @fan_rpm = 0
      @power_draw = 0
      @gpu_mode = 'Hybrid'
      @gpu_modes = %w[Integrated Hybrid]
      @gpu_index = 1
      @fan_enabled = false
      @profile = 'Balanced'
      @profiles = %w[Silent Balanced Turbo]
      @profile_index = 1
      @battery_limit = 80
      @battery_limits = [50, 60, 70, 80, 90, 100]
      @battery_index = 3
      @kb_effect = 'static'
      @kb_effects = %w[static breathe rainbow pulse comet]
      @kb_index = 0
      @overdrive = false
      refresh_stats
    end

    def init
      [self, Bubbletea.tick(1) { :tick }]
    end

    def update(message)
      case message
      when Bubbletea::WindowSizeMessage
        @term_width = message.width
        @term_height = message.height
        return [self, nil]
      when Bubbletea::KeyMessage
        case message.to_s
        when 'q', 'ctrl+c'
          return [self, Bubbletea.quit]
        when 'tab', 'right', 'l'
          @active_pane = (@active_pane + 1) % PANES.length
        when 'shift+tab', 'left', 'h'
          @active_pane = (@active_pane - 1) % PANES.length
        when 'j', 'down'
          adjust_pane(1)
        when 'k', 'up'
          adjust_pane(-1)
        when 'enter'
          activate_pane
        end
      when :tick
        refresh_stats
        return [self, Bubbletea.tick(1) { :tick }]
      end

      [self, nil]
    end

    def view
      s = Styles
      pane = PANES[@active_pane]
      col_w = pane_column_width

      cpu_box = s.pane('CPU', cpu_content, width: col_w, height: 5, active: pane == :cpu)
      gpu_box = s.pane('GPU', gpu_content, width: col_w, height: 5, active: pane == :gpu)
      fans_box = s.pane('Fans', fans_content, width: col_w, height: 5, active: pane == :fans)
      profile_box = s.pane('Profile', profile_content, width: col_w, height: 5, active: pane == :profile)
      battery_box = s.pane('Battery', battery_content, width: col_w, height: 5, active: pane == :battery)
      kb_box = s.pane('Keyboard', keyboard_content, width: col_w, height: 5, active: pane == :keyboard)
      panel_box = s.pane('Panel', panel_content, width: grid_width, height: 5, active: pane == :panel)

      row1 = side_by_side(cpu_box, gpu_box)
      row2 = side_by_side(fans_box, profile_box)
      row3 = side_by_side(battery_box, kb_box)

      time_str = Time.now.strftime('%H:%M:%S')
      header = s.status_bar(left_text: ' rog-helper ', right_text: " #{time_str} ", width: @term_width)
      hints = s.footer_bar(' ←/→ Tab pane · ↑/↓ adjust · Enter apply · q quit ', width: @term_width)

      <<~TEXT
        #{header}

        #{row1}

        #{row2}

        #{row3}

        #{panel_box}

        #{hints}
      TEXT
    end

    private

    def pane_column_width
      gap = 2
      ([@term_width - gap, 44].max / 2)
    end

    def grid_width
      2 * pane_column_width + 2
    end

    def side_by_side(left, right)
      left_lines = left.lines
      right_lines = right.lines
      max_lines = [left_lines.length, right_lines.length].max

      result = []
      max_lines.times do |i|
        l = left_lines[i] || ' ' * left_lines[0].length
        r = right_lines[i] || ' ' * right_lines[0].length
        result << "#{l}  #{r}"
      end
      result.join("\n")
    end

    def cpu_content
      s = Styles
      temp = s.temp_style(@cpu_temp)
      bar = s.bar(@cpu_temp, 100)
      [
        "Temperature  #{temp.render(bar)}",
        "             #{@cpu_temp}°C",
        "Fan          #{s.value.render("#{@fan_rpm} RPM")}",
        "Power        #{s.power_style(@power_draw).render("#{@power_draw}W")}"
      ].join("\n")
    end

    def gpu_content
      s = Styles
      modes = @gpu_modes.map.with_index do |m, i|
        prefix = i == @gpu_index ? '▸ ' : '  '
        style = i == @gpu_index ? s.selected : s.muted
        style.render("#{prefix}#{m}")
      end
      [
        "Mode         #{s.value.render(@gpu_mode)}",
        '',
        modes.join("\n")
      ].join("\n")
    end

    def fans_content
      s = Styles
      status =
        if @fan_enabled
          s.value.render('Custom curves on')
        else
          s.hint.render('Firmware auto')
        end
      [
        "Curves       #{status}",
        '',
        s.muted.render('Enter toggles custom fan curves')
      ].join("\n")
    end

    def profile_content
      s = Styles
      profiles = @profiles.map.with_index do |p, i|
        prefix = i == @profile_index ? '▸ ' : '  '
        style = i == @profile_index ? s.selected : s.muted
        style.render("#{prefix}#{p}")
      end
      [
        "Active       #{s.value.render(@profile)}",
        '',
        profiles.join("\n")
      ].join("\n")
    end

    def battery_content
      s = Styles
      limits = @battery_limits.map.with_index do |l, i|
        prefix = i == @battery_index ? '▸ ' : '  '
        style = i == @battery_index ? s.selected : s.muted
        style.render("#{prefix}#{l}%")
      end
      [
        "Limit        #{s.value.render("#{@battery_limit}%")}",
        '',
        limits.join("\n")
      ].join("\n")
    end

    def keyboard_content
      s = Styles
      effects = @kb_effects.map.with_index do |e, i|
        prefix = i == @kb_index ? '▸ ' : '  '
        style = i == @kb_index ? s.selected : s.muted
        style.render("#{prefix}#{e.capitalize}")
      end
      [
        "Effect       #{s.value.render(@kb_effect.capitalize)}",
        '',
        effects.join("\n")
      ].join("\n")
    end

    def panel_content
      s = Styles
      status = @overdrive ? s.value.render('On') : s.hint.render('Off')
      hint = @overdrive ? 'Faster response for gaming' : 'Better for battery'
      [
        "Overdrive    #{status}",
        '',
        s.hint.render(hint)
      ].join("\n")
    end

    def adjust_pane(direction)
      case PANES[@active_pane]
      when :gpu
        @gpu_index = (@gpu_index + direction) % @gpu_modes.length
      when :profile
        @profile_index = (@profile_index + direction) % @profiles.length
      when :battery
        @battery_index = (@battery_index + direction) % @battery_limits.length
      when :keyboard
        @kb_index = (@kb_index + direction) % @kb_effects.length
      when :panel
        @overdrive = !@overdrive
        begin
          Commands::Asusctl.set_panel_overdrive(@overdrive)
        rescue StandardError
          nil
        end
      end
    end

    def activate_pane
      case PANES[@active_pane]
      when :gpu
        @gpu_mode = @gpu_modes[@gpu_index]
        begin
          Commands::Supergfxctl.set_mode(@gpu_mode)
        rescue StandardError
          nil
        end
      when :fans
        @fan_enabled = !@fan_enabled
        begin
          Commands::Asusctl.enable_fan_curves(@fan_enabled)
        rescue StandardError
          nil
        end
      when :profile
        @profile = @profiles[@profile_index]
        begin
          Commands::Asusctl.set_profile(@profile)
        rescue StandardError
          nil
        end
      when :battery
        @battery_limit = @battery_limits[@battery_index]
        begin
          Commands::Asusctl.set_battery_limit(@battery_limit)
        rescue StandardError
          nil
        end
      when :keyboard
        @kb_effect = @kb_effects[@kb_index]
        begin
          Commands::Asusctl.set_aura_effect(@kb_effect)
        rescue StandardError
          nil
        end
      end
    end

    def refresh_stats
      @cpu_temp = SystemInfo.cpu_temp&.round(1) || 0
      @gpu_temp = SystemInfo.gpu_temp&.round(1) || 0
      @fan_rpm = SystemInfo.fan_rpm(:cpu)
      @power_draw = SystemInfo.power_draw&.round(1) || 0
      @gpu_mode = begin
        Commands::Supergfxctl.current_mode
      rescue StandardError
        @gpu_mode
      end
      begin
        sup = Commands::Supergfxctl.supported_modes
        @gpu_modes = sup if sup.any?
      rescue StandardError
        nil
      end
      @gpu_index = @gpu_modes.find_index { |m| m.to_s.casecmp(@gpu_mode.to_s).zero? } || 0
      @profile = begin
        Commands::Asusctl.current_profile
      rescue StandardError
        @profile
      end
      @profile_index = @profiles.index(@profile) || 1
      @battery_limit = begin
        Commands::Asusctl.battery_limit
      rescue StandardError
        @battery_limit
      end
      @battery_index = @battery_limits.index(@battery_limit) || 3
      @fan_enabled = begin
        Commands::Asusctl.fan_curves_enabled?
      rescue StandardError
        @fan_enabled
      end
      @overdrive = begin
        Commands::Asusctl.panel_overdrive
      rescue StandardError
        @overdrive
      end
    end
  end
end
