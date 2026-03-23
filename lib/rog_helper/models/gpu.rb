# frozen_string_literal: true

module RogHelper
  module Models
    class Gpu
      include Bubbletea::Model

      MODES = %w[Integrated Hybrid].freeze

      MODE_DESCRIPTIONS = {
        'Integrated' => 'iGPU only. Max battery life, GPU off.',
        'Hybrid' => 'Both GPUs. dGPU available for games/apps.'
      }.freeze

      def initialize
        @current_mode = 'Hybrid'
        @selected_index = 0
        @modes = MODES
        refresh
      end

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when 'up', 'k'
            @selected_index = (@selected_index - 1) % @modes.length
          when 'down', 'j'
            @selected_index = (@selected_index + 1) % @modes.length
          when 'enter'
            set_mode(@modes[@selected_index])
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
        selected_style = Styles.selected
        hint_style = Styles.hint

        mode_list = @modes.each_with_index.map do |mode, i|
          prefix = i == @selected_index ? '▸ ' : '  '
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{mode}")
        end

        desc = MODE_DESCRIPTIONS[@modes[@selected_index]]

        content = <<~TEXT
          #{title_style.render('GPU Mode')}

          #{label_style.render('Active')}     #{value_style.render(@current_mode)}

          #{label_style.render('Available')}
          #{mode_list.join("\n")}

          #{hint_style.render(desc)}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @current_mode = begin
          Commands::Supergfxctl.current_mode
        rescue StandardError
          'Unknown'
        end
        @selected_index = @modes.index(@current_mode) || 0
      end

      def set_mode(mode)
        Commands::Supergfxctl.set_mode(mode)
        refresh
      end
    end
  end
end
