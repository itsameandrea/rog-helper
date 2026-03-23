# frozen_string_literal: true

module RogHelper
  module Styles
    module_function

    def title
      Lipgloss::Style.new
                     .bold(true)
                     .foreground('#7D56F4')
    end

    def tab_active
      Lipgloss::Style.new
                     .bold(true)
                     .foreground('#FFFFFF')
                     .background('#7D56F4')
                     .padding(0, 1)
    end

    def tab_inactive
      Lipgloss::Style.new
                     .foreground('#888888')
                     .padding(0, 1)
    end

    def selected
      Lipgloss::Style.new
                     .foreground('#7D56F4')
                     .bold(true)
    end

    def value
      Lipgloss::Style.new
                     .foreground('#00FF00')
    end

    def warning
      Lipgloss::Style.new
                     .foreground('#FFAA00')
    end

    def error
      Lipgloss::Style.new
                     .foreground('#FF0000')
    end

    def label
      Lipgloss::Style.new
                     .foreground('#AAAAAA')
    end

    def border
      Lipgloss::Style.new
                     .border(:rounded)
                     .border_foreground('#7D56F4')
                     .padding(1, 2)
    end
  end
end
