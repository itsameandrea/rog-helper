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

    def title
      Lipgloss::Style.new
                     .bold(true)
                     .foreground(ACCENT)
    end

    def tab_active
      Lipgloss::Style.new
                     .bold(true)
                     .foreground(BG)
                     .background(ACCENT)
                     .padding(0, 1)
    end

    def tab_inactive
      Lipgloss::Style.new
                     .foreground(MUTED)
                     .padding(0, 1)
    end

    def selected
      Lipgloss::Style.new
                     .foreground(ACCENT)
                     .bold(true)
    end

    def value
      Lipgloss::Style.new
                     .foreground(GREEN)
    end

    def value_high
      Lipgloss::Style.new
                     .foreground(YELLOW)
    end

    def value_critical
      Lipgloss::Style.new
                     .foreground(RED)
    end

    def hint
      Lipgloss::Style.new
                     .foreground(MUTED)
                     .italic(true)
    end

    def label
      Lipgloss::Style.new
                     .foreground(FG)
    end

    def border
      Lipgloss::Style.new
                     .border(:rounded)
                     .border_foreground(MUTED)
                     .padding(1, 2)
    end

    def border_accent
      Lipgloss::Style.new
                     .border(:rounded)
                     .border_foreground(ACCENT)
                     .padding(1, 2)
    end
  end
end
