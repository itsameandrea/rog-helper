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
        Styles.value_high
        Styles.hint

        cpu_style = temp_style(@cpu_temp)
        gpu_style = temp_style(@gpu_temp)
        power_style = power_style(@power_draw)

        content = <<~TEXT
          #{title_style.render('Dashboard')}

          #{label_style.render('CPU Temp')}    #{cpu_style.render(bar(@cpu_temp, 100))} #{@cpu_temp}°C
          #{label_style.render('GPU Temp')}    #{gpu_style.render(bar(@gpu_temp, 100))} #{@gpu_temp}°C

          #{label_style.render('Fans')}        #{value_style.render("#{@fan_rpm} RPM")}
          #{label_style.render('Power')}       #{power_style.render("#{@power_draw}W")}

          #{label_style.render('GPU Mode')}    #{value_style.render(@gpu_mode)}
          #{label_style.render('Profile')}     #{value_style.render(@profile)}
        TEXT

        border_style.render(content)
      end

      private

      def bar(value, max)
        width = 20
        filled = [(value.to_f / max * width).round, width].min
        empty = width - filled
        '█' * filled + '░' * empty
      end

      def temp_style(temp)
        if temp > 80
          Styles.value_critical
        elsif temp > 65
          Styles.value_high
        else
          Styles.value
        end
      end

      def power_style(watts)
        if watts > 20
          Styles.value_critical
        elsif watts > 10
          Styles.value_high
        else
          Styles.value
        end
      end

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
