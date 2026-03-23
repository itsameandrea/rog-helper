# frozen_string_literal: true

module RogHelper
  class App
    include Bubbletea::Model

    PANES = %i[cpu gpu fans profile battery keyboard panel].freeze

    def initialize
      @active_pane = 0
      @term_width = 80
      @cpu_temp = 0
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
      w = [@term_width, 50].max

      time_str = Time.now.strftime('%H:%M:%S')
      header = "#{s.accent.render('rog-helper')} #{s.muted.render(time_str)}"

      boxes = PANES.map do |name|
        title = name.to_s.capitalize
        content = send("#{name}_content")
        s.pane(title, content, width: w, height: 4, active: pane == name)
      end

      footer = s.hint.render(' ←/→ focus · ↑/↓ adjust · Enter apply · q quit')

      [header, '', *boxes, '', footer].join("\n")
    end

    private

    def cpu_content
      s = Styles
      bar = s.bar(@cpu_temp, 100)
      temp_c = s.temp_style(@cpu_temp)
      "Temp #{temp_c.render(bar)} #{@cpu_temp}C   Fan #{s.value.render("#{@fan_rpm} RPM")}   Power #{s.power_style(@power_draw).render("#{@power_draw}W")}"
    end

    def gpu_content
      s = Styles
      modes = @gpu_modes.map.with_index do |m, i|
        i == @gpu_index ? s.selected.render(">#{m}") : s.muted.render(" #{m}")
      end.join(' ')
      "Mode: #{s.value.render(@gpu_mode)}   #{modes}"
    end

    def fans_content
      s = Styles
      status = @fan_enabled ? s.value.render('Custom') : s.muted.render('Auto')
      "Curves: #{status}"
    end

    def profile_content
      s = Styles
      list = @profiles.map.with_index do |p, i|
        i == @profile_index ? s.selected.render(">#{p}") : s.muted.render(" #{p}")
      end.join(' ')
      "Active: #{s.value.render(@profile)}   #{list}"
    end

    def battery_content
      s = Styles
      list = @battery_limits.map.with_index do |l, i|
        i == @battery_index ? s.selected.render(">#{l}%") : s.muted.render(" #{l}%")
      end.join(' ')
      "Limit: #{s.value.render("#{@battery_limit}%")}   #{list}"
    end

    def keyboard_content
      s = Styles
      list = @kb_effects.map.with_index do |e, i|
        i == @kb_index ? s.selected.render(">#{e.capitalize}") : s.muted.render(" #{e.capitalize}")
      end.join(' ')
      "Effect: #{s.value.render(@kb_effect.capitalize)}   #{list}"
    end

    def panel_content
      s = Styles
      status = @overdrive ? s.value.render('On') : s.muted.render('Off')
      hint = @overdrive ? 'Gaming' : 'Battery saver'
      "Overdrive: #{status}   #{s.hint.render(hint)}"
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
        Commands::Asusctl.set_panel_overdrive(@overdrive) rescue nil
      end
    end

    def activate_pane
      case PANES[@active_pane]
      when :gpu
        @gpu_mode = @gpu_modes[@gpu_index]
        Commands::Supergfxctl.set_mode(@gpu_mode) rescue nil
      when :fans
        @fan_enabled = !@fan_enabled
        Commands::Asusctl.enable_fan_curves(@fan_enabled) rescue nil
      when :profile
        @profile = @profiles[@profile_index]
        Commands::Asusctl.set_profile(@profile) rescue nil
      when :battery
        @battery_limit = @battery_limits[@battery_index]
        Commands::Asusctl.set_battery_limit(@battery_limit) rescue nil
      when :keyboard
        @kb_effect = @kb_effects[@kb_index]
        Commands::Asusctl.set_aura_effect(@kb_effect) rescue nil
      end
    end

    def refresh_stats
      @cpu_temp = SystemInfo.cpu_temp&.round(1) || 0
      @fan_rpm = SystemInfo.fan_rpm(:cpu)
      @power_draw = SystemInfo.power_draw&.round(1) || 0
      @gpu_mode = Commands::Supergfxctl.current_mode rescue @gpu_mode
      begin
        sup = Commands::Supergfxctl.supported_modes
        @gpu_modes = sup if sup.any?
      rescue StandardError
        nil
      end
      @gpu_index = @gpu_modes.find_index { |m| m.to_s.casecmp(@gpu_mode.to_s).zero? } || 0
      @profile = Commands::Asusctl.current_profile rescue @profile
      @profile_index = @profiles.index(@profile) || 1
      @battery_limit = Commands::Asusctl.battery_limit rescue @battery_limit
      @battery_index = @battery_limits.index(@battery_limit) || 3
      @fan_enabled = Commands::Asusctl.fan_curves_enabled? rescue @fan_enabled
      @overdrive = Commands::Asusctl.panel_overdrive rescue @overdrive
    end
  end
end
