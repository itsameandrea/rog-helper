# frozen_string_literal: true

module RogHelper
  module Models
    class Fans
      include Bubbletea::Model

      def initialize
        @enabled = false
        @profiles = %w[Silent Balanced Turbo]
        @current_profile = 'Balanced'
        @selected_profile = 1
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
            @selected_profile = (@selected_profile - 1) % @profiles.length
          when 'down', 'j'
            @selected_profile = (@selected_profile + 1) % @profiles.length
          when 'enter'
            toggle_fan_curves
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

        if @enabled
          control_status = value_style.render('Custom')
          hint = 'Using your fan curve settings.'
        else
          control_status = hint_style.render('Auto')
          hint = 'Firmware controls fans automatically.'
        end

        profile_list = @profiles.each_with_index.map do |profile, i|
          prefix = i == @selected_profile ? '▸ ' : '  '
          style = i == @selected_profile ? selected_style : label_style
          style.render("#{prefix}#{profile}")
        end

        content = <<~TEXT
          #{title_style.render('Fan Curves')}

          #{label_style.render('Mode')}       #{control_status}
          #{label_style.render('Profile')}    #{value_style.render(@current_profile)}

          #{label_style.render('Profiles')}
          #{profile_list.join("\n")}

          #{hint_style.render(hint)}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        @enabled = begin
          Commands::Asusctl.fan_curves_enabled?
        rescue StandardError
          false
        end
        @current_profile = begin
          Commands::Asusctl.current_profile
        rescue StandardError
          'Balanced'
        end
        @selected_profile = @profiles.index(@current_profile) || 1
      end

      def toggle_fan_curves
        Commands::Asusctl.enable_fan_curves(!@enabled)
        refresh
      end
    end
  end
end
