# frozen_string_literal: true

module RogHelper
  module Commands
    module Asusctl
      module_function

      def available?
        system('which asusctl > /dev/null 2>&1')
      end

      def current_profile
        result = `asusctl profile get 2>/dev/null`
        result.match(/Active profile: (\w+)/)&.captures&.first
      end

      def list_profiles
        result = `asusctl profile list 2>/dev/null`
        result.lines.map { |l| l.strip }.reject(&:empty?)
      end

      def set_profile(name)
        system("asusctl profile set #{name}")
      end

      def fan_curves_enabled?
        result = `asusctl fan-curve --get-enabled 2>/dev/null`
        result.include?('true')
      end

      def fan_curve_data(profile)
        result = `asusctl fan-curve --mod-profile #{profile} 2>/dev/null`
        result.strip
      end

      def set_fan_curve(profile:, fan:, data:)
        system("asusctl fan-curve --mod-profile #{profile} --fan #{fan} --data '#{data}'")
      end

      def enable_fan_curves(enabled)
        system("asusctl fan-curve --enable-fan-curves #{enabled}")
      end

      def reset_fan_curve(profile)
        system("asusctl fan-curve --default --mod-profile #{profile}")
      end

      def battery_limit
        result = `asusctl battery info 2>/dev/null`
        result.match(/(\d+)%/)&.captures&.first&.to_i
      end

      def set_battery_limit(percent)
        system("asusctl battery limit #{percent}")
      end

      def battery_oneshot(percent = nil)
        cmd = 'asusctl battery oneshot'
        cmd += " #{percent}" if percent
        system(cmd)
      end

      def panel_overdrive
        result = `asusctl armoury get panel_overdrive 2>/dev/null`
        result.include?('(1)')
      end

      def set_panel_overdrive(enabled)
        value = enabled ? '1' : '0'
        system("asusctl armoury set panel_overdrive #{value}")
      end

      def aura_effects
        result = `asusctl aura effect --help 2>/dev/null`
        result.scan(/(\w+)\s/).flatten
      end

      def set_aura_effect(effect)
        system("asusctl aura effect #{effect}")
      end
    end
  end
end
