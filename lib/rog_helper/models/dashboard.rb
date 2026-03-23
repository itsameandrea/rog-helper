# frozen_string_literal: true

module RogHelper
  module Models
    class Dashboard
      include Bubbletea::Model

      def initialize
        @cpu_temp = 0
        @gpu_temp = 0
        @fan_rpm = 0
        @power_draw = 0
        @gpu_mode = 'Unknown'
        @profile = 'Unknown'
        @spinner = Bubbles::Spinner.new
      end

      def init
        [self, @spinner.tick]
      end

      def update(message)
        case message
        when Bubbletea::KeyMessage
          case message.to_s
          when 'q', 'ctrl+c'
            return [self, Bubbletea.quit]
          end
        when :tick
          refresh_stats
          return [self, Bubbletea.tick(1) { :tick }]
        end

        @spinner, command = @spinner.update(message)
        [self, command]
      end

      def view
        border_style = Styles.border
        title_style = Styles.title
        label_style = Styles.label
        value_style = Styles.value

        content = <<~TEXT
          #{title_style.render('System Dashboard')}

          #{label_style.render('CPU Temp:')}     #{value_style.render("#{@cpu_temp}°C")}
          #{label_style.render('GPU Temp:')}     #{value_style.render("#{@gpu_temp}°C")}
          #{label_style.render('Fan RPM:')}      #{value_style.render("#{@fan_rpm} RPM")}
          #{label_style.render('Power Draw:')}   #{value_style.render("#{@power_draw}W")}
          #{label_style.render('GPU Mode:')}     #{value_style.render(@gpu_mode)}
          #{label_style.render('Profile:')}      #{value_style.render(@profile)}

          #{@spinner.view} Refreshing...
        TEXT

        border_style.render(content)
      end

      private

      def refresh_stats
        @cpu_temp = SystemInfo.cpu_temp&.round(1) || 0
        @gpu_temp = SystemInfo.gpu_temp&.round(1) || 0
        @fan_rpm = SystemInfo.fan_rpm(:cpu)
        @power_draw = SystemInfo.power_draw&.round(1) || 0
        @gpu_mode = begin
          Commands::Supergfxctl.current_mode
        rescue StandardError
          'Unknown'
        end
        @profile = begin
          Commands::Asusctl.current_profile
        rescue StandardError
          'Unknown'
        end
      end
    end
  end
end
