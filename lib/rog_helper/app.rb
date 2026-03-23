# frozen_string_literal: true

module RogHelper
  class App
    include Bubbletea::Model

    TABS = [
      { name: 'Dashboard', model: Models::Dashboard },
      { name: 'GPU', model: Models::Gpu },
      { name: 'Fans', model: Models::Fans },
      { name: 'Profiles', model: Models::Profiles },
      { name: 'Battery', model: Models::Battery },
      { name: 'Keyboard', model: Models::Keyboard },
      { name: 'Panel', model: Models::Panel }
    ].freeze

    def initialize
      @current_tab = 0
      @models = TABS.map { |tab| tab[:model].new }
    end

    def init
      [self, Bubbletea.tick(1) { :tick }]
    end

    def update(message)
      case message
      when Bubbletea::KeyMessage
        case message.to_s
        when 'q', 'ctrl+c'
          return [self, Bubbletea.quit]
        when 'tab', 'right', 'l'
          @current_tab = (@current_tab + 1) % TABS.length
        when 'shift+tab', 'left', 'h'
          @current_tab = (@current_tab - 1) % TABS.length
        end
      when :tick
        @models[0], = @models[0].update(:tick)
        return [self, Bubbletea.tick(1) { :tick }]
      end

      @models[@current_tab], command = @models[@current_tab].update(message)
      [self, command]
    end

    def view
      title_style = Styles.title
      tab_active_style = Styles.tab_active
      tab_inactive_style = Styles.tab_inactive

      tabs = TABS.each_with_index.map do |tab, i|
        if i == @current_tab
          tab_active_style.render(tab[:name])
        else
          tab_inactive_style.render(tab[:name])
        end
      end

      header = '  rog-helper  '
      tab_bar = tabs.join(' │ ')

      <<~TEXT
        #{title_style.render(header)}
        #{tab_bar}
        #{'─' * 50}

        #{@models[@current_tab].view}

        #{tab_inactive_style.render('  [Tab] next  [Shift+Tab] prev  [q] quit')}
      TEXT
    end
  end
end
