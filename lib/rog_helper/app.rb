# frozen_string_literal: true

module RogHelper
  class App
    include Bubbletea::Model

    def initialize
      @active = 0
      @width = 80
      @cpu_temp = 0
      @fan_rpm = 0
      @power = 0
      @gpu_mode = 'Hybrid'
      @gpu_modes = %w[Integrated Hybrid Vfio AsusMuxDgpu]
      @gpu_idx = 1
      @fan_on = false
      @profile = 'Balanced'
      @profiles = %w[Silent Balanced Turbo]
      @prof_idx = 1
      @bat_lim = 80
      @bat_lims = [50, 60, 70, 80, 90, 100]
      @bat_idx = 3
      @kb_eff = 'static'
      @kb_effs = %w[static breathe rainbow pulse comet]
      @kb_idx = 0
      @od = false
      refresh
    end

    def init
      [self, Bubbletea.tick(1) { :tick }]
    end

    def update(msg)
      case msg
      when Bubbletea::WindowSizeMessage
        @width = msg.width
      when Bubbletea::KeyMessage
        case msg.to_s
        when 'q', 'ctrl+c' then return [self, Bubbletea.quit]
        when 'right', 'l' then @active = (@active + 1) % 7
        when 'left', 'h' then @active = (@active - 1) % 7
        when 'down', 'j' then move(1)
        when 'up', 'k' then move(-1)
        when 'enter' then apply
        end
      when :tick
        refresh
        return [self, Bubbletea.tick(1) { :tick }]
      end
      [self, nil]
    end

    def view
      s = Styles
      w = [(@width - 4) / 2, 38].min
      time = Time.now.strftime('%H:%M:%S')

      header = "#{s.accent.render('rog-helper')} #{s.muted.render(time)}"
      footer = s.hint.render(' h/l focus · j/k adjust · Enter apply · q quit')

      row1 = join_h(box('CPU', cpu_body, 0, w), box('GPU', gpu_body, 1, w))
      row2 = join_h(box('Fans', fans_body, 2, w), box('Profile', prof_body, 3, w))
      row3 = join_h(box('Battery', bat_body, 4, w), box('Keyboard', kb_body, 5, w))
      row4 = box('Panel', panel_body, 6, w * 2 + 1)

      [header, '', row1, row2, row3, row4, '', footer].join("\n")
    end

    private

    def join_h(l, r)
      l.split("\n").zip(r.split("\n")).map { |a, b| (a || '') + (b || '') }.join("\n")
    end

    def box(title, body, idx, width)
      active = @active == idx
      border = active ? Lipgloss::Border::THICK : Lipgloss::Border::NORMAL
      color = active ? Styles::ACCENT : Styles::MUTED

      Lipgloss::Style.new
        .border(border)
        .border_foreground(color)
        .width(width).height(4)
        .render("#{title}\n#{body}")
    end

    def cpu_body
      s = Styles
      bar = s.bar(@cpu_temp, 100)
      "#{s.temp_style(@cpu_temp).render(bar)} #{@cpu_temp}C  Fan #{s.value.render("#{@fan_rpm} RPM")}  Pwr #{s.power_style(@power).render("#{@power}W")}"
    end

    def gpu_body
      s = Styles
      m = @gpu_modes.map.with_index { |x, i| i == @gpu_idx ? s.selected.render(x) : s.muted.render(x) }.join(' ')
      "#{s.value.render(@gpu_mode)}\n#{m}"
    end

    def fans_body
      s = Styles
      st = @fan_on ? s.value.render('Custom') : s.muted.render('Auto')
      "Curves: #{st}"
    end

    def prof_body
      s = Styles
      list = @profiles.map.with_index { |x, i| i == @prof_idx ? s.selected.render(x) : s.muted.render(x) }.join(' ')
      "#{s.value.render(@profile)}\n#{list}"
    end

    def bat_body
      s = Styles
      list = @bat_lims.map.with_index { |x, i| i == @bat_idx ? s.selected.render("#{x}%") : s.muted.render("#{x}%") }.join(' ')
      "#{s.value.render("#{@bat_lim}%")}\n#{list}"
    end

    def kb_body
      s = Styles
      list = @kb_effs.map.with_index { |x, i| i == @kb_idx ? s.selected.render(x.capitalize) : s.muted.render(x.capitalize) }.join(' ')
      "#{s.value.render(@kb_eff.capitalize)}\n#{list}"
    end

    def panel_body
      s = Styles
      st = @od ? s.value.render('On') : s.muted.render('Off')
      "Overdrive: #{st}"
    end

    def move(dir)
      case @active
      when 1 then @gpu_idx = (@gpu_idx + dir) % @gpu_modes.length
      when 3 then @prof_idx = (@prof_idx + dir) % @profiles.length
      when 4 then @bat_idx = (@bat_idx + dir) % @bat_lims.length
      when 5 then @kb_idx = (@kb_idx + dir) % @kb_effs.length
      when 6 then @od = !@od; Commands::Asusctl.set_panel_overdrive(@od) rescue nil
      end
    end

    def apply
      case @active
      when 1 then @gpu_mode = @gpu_modes[@gpu_idx]; Commands::Supergfxctl.set_mode(@gpu_mode) rescue nil
      when 2 then @fan_on = !@fan_on; Commands::Asusctl.enable_fan_curves(@fan_on) rescue nil
      when 3 then @profile = @profiles[@prof_idx]; Commands::Asusctl.set_profile(@profile) rescue nil
      when 4 then @bat_lim = @bat_lims[@bat_idx]; Commands::Asusctl.set_battery_limit(@bat_lim) rescue nil
      when 5 then @kb_eff = @kb_effs[@kb_idx]; Commands::Asusctl.set_aura_effect(@kb_eff) rescue nil
      end
    end

    def refresh
      @cpu_temp = SystemInfo.cpu_temp&.round(1) || 0
      @fan_rpm = SystemInfo.fan_rpm(:cpu)
      @power = SystemInfo.power_draw&.round(1) || 0
      @gpu_mode = Commands::Supergfxctl.current_mode rescue @gpu_mode
      begin
        sup = Commands::Supergfxctl.supported_modes
        @gpu_modes = sup if sup.any?
      rescue StandardError
        nil
      end
      @gpu_idx = @gpu_modes.find_index { |m| m.to_s.casecmp(@gpu_mode.to_s).zero? } || 0
      @profile = Commands::Asusctl.current_profile rescue @profile
      @prof_idx = @profiles.index(@profile) || 1
      @bat_lim = Commands::Asusctl.battery_limit rescue @bat_lim
      @bat_idx = @bat_lims.index(@bat_lim) || 3
      @fan_on = Commands::Asusctl.fan_curves_enabled? rescue @fan_on
      @od = Commands::Asusctl.panel_overdrive rescue @od
    end
  end
end
