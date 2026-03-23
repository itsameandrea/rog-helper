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

        if @overdrive
          status = value_style.render('On')
          hint = 'Faster response time. Good for gaming.'
        else
          status = label_style.render('Off')
          hint = 'Lower power use. Better for battery.'
        end

        content = <<~TEXT
          #{title_style.render('Display Overdrive')}

          #{label_style.render('Status:')} #{status}
          #{label_style.render("  #{hint}")}

          #{label_style.render('Reduces motion blur by driving pixels harder.')}
          #{label_style.render('May cause slight artifacts in some scenes.')}

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
