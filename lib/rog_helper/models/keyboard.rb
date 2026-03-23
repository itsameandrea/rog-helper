# frozen_string_literal: true

module RogHelper
  module Models
    class Keyboard
      include Bubbletea::Model

      EFFECTS = %w[
        static breathe rainbow pulse comet
        flash dash adaptive
      ].freeze

      def initialize
        @effects = EFFECTS
        @selected_index = 0
        @current_effect = 'static'
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when 'up', 'k'
            @selected_index = (@selected_index - 1) % @effects.length
          when 'down', 'j'
            @selected_index = (@selected_index + 1) % @effects.length
          when 'enter'
            set_effect(@effects[@selected_index])
          end
        end

        [self, nil]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value
        selected_style = Styles.selected

        effect_list = @effects.each_with_index.map do |effect, i|
          prefix = i == @selected_index ? '→ ' : '  '
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{effect.capitalize}")
        end

        content = <<~TEXT
          #{title_style.render('Keyboard Backlight')}

          #{label_style.render('Current Effect:')}  #{value_style.render(@current_effect.capitalize)}

          #{label_style.render('Available effects:')}
          #{effect_list.join("\n")}

          #{label_style.render('[Enter] to select')}
        TEXT

        border_style.render(content)
      end

      private

      def set_effect(effect)
        Commands::Asusctl.set_aura_effect(effect)
        @current_effect = effect
      end
    end
  end
end
