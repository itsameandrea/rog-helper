# frozen_string_literal: true

module RogHelper
  module Models
    class Profiles
      include Bubbletea::Model

      def initialize
        @profiles = %w[Silent Balanced Turbo]
        @current_profile = 'Balanced'
        @selected_index = 1
        refresh
      end

      PROFILE_DESCRIPTIONS = {
        'Silent' => 'Quiet fans, lower performance.',
        'Balanced' => 'Good mix of noise and speed.',
        'Turbo' => 'Max performance, louder fans.'
      }.freeze

      def init
        [self, nil]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when 'up', 'k'
            @selected_index = (@selected_index - 1) % @profiles.length
          when 'down', 'j'
            @selected_index = (@selected_index + 1) % @profiles.length
          when 'enter'
            set_profile(@profiles[@selected_index])
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

        profile_list = @profiles.each_with_index.map do |profile, i|
          prefix = i == @selected_index ? '▸ ' : '  '
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{profile}")
        end

        desc = PROFILE_DESCRIPTIONS[@profiles[@selected_index]]

        content = <<~TEXT
          #{title_style.render('Performance Profile')}

          #{label_style.render('Active')}     #{value_style.render(@current_profile)}

          #{label_style.render('Available')}
          #{profile_list.join("\n")}

          #{hint_style.render(desc)}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @current_profile = begin
          Commands::Asusctl.current_profile
        rescue StandardError
          'Unknown'
        end
        @selected_index = @profiles.index(@current_profile) || 1
      end

      def set_profile(profile)
        Commands::Asusctl.set_profile(profile)
        refresh
      end
    end
  end
end
