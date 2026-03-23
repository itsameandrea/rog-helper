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
        warning_style = Styles.warning

        status = @overdrive ? value_style.render('Enabled') : warning_style.render('Disabled')

        content = <<~TEXT
          #{title_style.render('Panel Settings')}

          #{label_style.render('Overdrive:')}  #{status}

          #{label_style.render('[Enter] to toggle  [r] to refresh')}
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
