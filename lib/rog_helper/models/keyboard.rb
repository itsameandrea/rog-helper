# frozen_string_literal: true

module RogHelper
  module Models
    class Keyboard
      include Bubbletea::Model

      EFFECTS = %w[
        static breathe rainbow pulse comet
        flash dash adaptive
      ].freeze

      EFFECT_DESCRIPTIONS = {
        'static' => 'Solid color, no animation.',
        'breathe' => 'Slow fade in and out.',
        'rainbow' => 'Cycling colors across keys.',
        'pulse' => 'Brightness pulses up and down.',
        'comet' => 'Light streaks across keyboard.',
        'flash' => 'Quick flash on keypress.',
        'dash' => 'Fast dash animation.',
        'adaptive' => 'Changes with system activity.'
      }.freeze

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
        hint_style = Styles.label

        effect_list = @effects.each_with_index.map do |effect, i|
          prefix = i == @selected_index ? '→ ' : '  '
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{effect.capitalize}")
        end

        desc = EFFECT_DESCRIPTIONS[@effects[@selected_index]]

        content = <<~TEXT
          #{title_style.render('Keyboard Backlight')}

          #{label_style.render('Now:')} #{value_style.render(@current_effect.capitalize)}

          #{label_style.render('Effects:')}
          #{effect_list.join("\n")}

          #{hint_style.render(desc)}

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
