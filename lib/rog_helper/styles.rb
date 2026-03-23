# frozen_string_literal: true

module RogHelper
  module Styles
    module_function

    BG = '#1a1b26'
    FG = '#a9b1d6'
    MUTED = '#565f89'
    ACCENT = '#7aa2f7'
    GREEN = '#9ece6a'
    YELLOW = '#e0af68'
    RED = '#f7768e'
    CYAN = '#7dcfff'
    PURPLE = '#bb9af7'

    def accent
      Lipgloss::Style.new.bold(true).foreground(ACCENT)
    end

    def muted
      Lipgloss::Style.new.foreground(MUTED)
    end

    def value
      Lipgloss::Style.new.foreground(GREEN)
    end

    def value_high
      Lipgloss::Style.new.foreground(YELLOW)
    end

    def value_critical
      Lipgloss::Style.new.foreground(RED)
    end

    def hint
      Lipgloss::Style.new.foreground(MUTED).italic(true)
    end

    def selected
      Lipgloss::Style.new.bold(true).foreground(ACCENT)
    end

    def pane(title, content, width:, height:, active: false)
      border_kind = active ? Lipgloss::Border::THICK : Lipgloss::Border::NORMAL
      border_color = active ? ACCENT : MUTED
      title_styled = active ? accent.render(title) : muted.render(title)

      box = Lipgloss::Style.new
                           .border(border_kind)
                           .border_foreground(border_color)
                           .padding(0, 1)
                           .width(width - 2)
                           .height(height - 2)
                           .render(content)

      lines = box.lines
      title_with_space = " #{title_styled} "
      prefix_len = 2
      new_top = lines[0][0...prefix_len] + title_with_space + lines[0][(prefix_len + title.length + 2)..]
      lines[0] = new_top

      lines.join("\n")
    end

    def status_bar(left_text:, right_text:, width:)
      w = [width, 20].max
      l = left_text.length
      r = right_text.length
      dash_total = w - l - r - 2
      dash_total = [dash_total, 2].max
      left_d = dash_total / 2
      right_d = dash_total - left_d
      "#{accent.render('╭')}#{muted.render('─' * left_d)}#{accent.render(left_text)}" \
        "#{muted.render('─' * right_d)}#{muted.render(right_text)}#{accent.render('╮')}"
    end

    def footer_bar(text, width:)
      w = [width, 20].max
      inner = w - 2
      bar = muted.render('─' * inner)
      "#{muted.render('╰')}#{bar}#{muted.render('╯')}\n#{hint.render(text)}"
    end

    def bar(value, max, width: 16)
      filled = [(value.to_f / max * width).round, width].min
      empty = width - filled
      '█' * filled + '░' * empty
    end

    def temp_style(temp)
      if temp > 80
        value_critical
      elsif temp > 65
        value_high
      else
        value
      end
    end

    def power_style(watts)
      if watts > 20
        value_critical
      elsif watts > 10
        value_high
      else
        value
      end
    end
  end
end
