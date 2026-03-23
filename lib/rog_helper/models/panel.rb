# frozen_string_literal: true

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
          when 'enter'
            toggle_overdrive
          when 'r'
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
        hint_style = Styles.hint

        if @overdrive
          status = value_style.render('On')
          hint = 'Faster response. Good for gaming.'
        else
          status = hint_style.render('Off')
          hint = 'Better for battery life.'
        end

        content = <<~TEXT
          #{title_style.render('Display Overdrive')}

          #{label_style.render('Status')}     #{status}

          #{hint_style.render(hint)}
          #{hint_style.render('Reduces motion blur. May cause artifacts.')}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @overdrive = begin
          Commands::Asusctl.panel_overdrive
        rescue StandardError
          false
        end
      end

      def toggle_overdrive
        Commands::Asusctl.set_panel_overdrive(!@overdrive)
        refresh
      end
    end
  end
end
