# frozen_string_literal: true

module RogHelper
  module Models
    class Battery
      include Bubbletea::Model

      LIMITS = [50, 60, 70, 80, 90, 100].freeze

      def initialize
        @current_limit = 100
        @selected_index = LIMITS.index(80) || 12
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
            @selected_index = (@selected_index - 1) % LIMITS.length
          when 'down', 'j'
            @selected_index = (@selected_index + 1) % LIMITS.length
          when 'enter'
            set_limit(LIMITS[@selected_index])
          when 'o'
            oneshot
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

        limit_list = LIMITS.each_with_index.map do |limit, i|
          prefix = i == @selected_index ? '→ ' : '  '
          style = i == @selected_index ? selected_style : label_style
          style.render("#{prefix}#{limit}%")
        end

        content = <<~TEXT
          #{title_style.render('Battery')}

          #{label_style.render('Charge limit:')} #{value_style.render("#{@current_limit}%")}
          #{label_style.render('  Battery stops charging at this level.')}

          #{label_style.render('Set new limit:')}
          #{limit_list.join("\n")}

          #{label_style.render('[Enter] to set  [o] charge to 100% once  [r] refresh')}
        TEXT

        border_style.render(content)
      end

      private

      def refresh
        limit = begin
          Commands::Asusctl.battery_limit
        rescue StandardError
          100
        end
        @current_limit = limit || 100
        @selected_index = LIMITS.index(@current_limit) || 12
      end

      def set_limit(percent)
        Commands::Asusctl.set_battery_limit(percent)
        refresh
      end

      def oneshot
        Commands::Asusctl.battery_oneshot
        refresh
      end
    end
  end
end
