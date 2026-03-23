# frozen_string_literal: true

module RogHelper
  module SystemInfo
    module_function

    def cpu_temp
      paths = Dir.glob('/sys/class/hwmon/hwmon*/temp1_input')
      paths.each do |path|
        temp = File.read(path).strip.to_i / 1000.0
        return temp if temp > 0
      rescue StandardError
        next
      end
      nil
    end

    def gpu_temp
      if File.exist?('/usr/bin/nvidia-smi')
        result = `nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null`
        return result.strip.to_i if result && !result.strip.empty?
      end

      hwmon_dirs = Dir.glob('/sys/class/hwmon/hwmon*')
      hwmon_dirs.each do |dir|
        name = begin
          File.read("#{dir}/name").strip
        rescue StandardError
          next
        end

        next unless name.include?('amdgpu')

        temp_path = "#{dir}/temp1_input"
        return File.read(temp_path).strip.to_i / 1000.0 if File.exist?(temp_path)
      end
      nil
    end

    def fan_rpm(fan_type = :cpu)
      hwmon_dirs = Dir.glob('/sys/class/hwmon/hwmon*')
      hwmon_dirs.each do |dir|
        name = begin
          File.read("#{dir}/name").strip
        rescue StandardError
          next
        end

        case fan_type
        when :cpu
          if name.include?('asus') || name.include?('k10temp')
            rpm = begin
              File.read("#{dir}/fan1_input").strip.to_i
            rescue StandardError
              0
            end
            return rpm if rpm > 0
          end
        when :gpu
          if name.include?('nvidia') || name.include?('amdgpu')
            rpm = begin
              File.read("#{dir}/fan1_input").strip.to_i
            rescue StandardError
              0
            end
            return rpm if rpm > 0
          end
        end
      end
      0
    end

    def power_draw
      path = '/sys/class/power_supply/BAT0/power_now'
      return unless File.exist?(path)

      File.read(path).strip.to_i / 1_000_000.0
    end

    def battery_percent
      path = '/sys/class/power_supply/BAT0/capacity'
      return unless File.exist?(path)

      File.read(path).strip.to_i
    end

    def on_battery?
      ac_online = '/sys/class/power_supply/AC/online'
      return File.read(ac_online).strip == '0' if File.exist?(ac_online)

      bat_status = '/sys/class/power_supply/BAT0/status'
      File.exist?(bat_status) && File.read(bat_status).strip.casecmp('discharging').zero?
    end

    def power_state
      on_battery? ? :battery : :plugged
    end

    def cpu_power
      hwmon_dirs = Dir.glob('/sys/class/hwmon/hwmon*')
      hwmon_dirs.each do |dir|
        name = begin
          File.read("#{dir}/name").strip
        rescue StandardError
          next
        end

        next unless name.include?('amdgpu')

        power_path = "#{dir}/power1_input"
        return (File.read(power_path).strip.to_i / 1_000_000.0).round(1) if File.exist?(power_path)
      end
      nil
    end

    def gpu_power
      if File.exist?('/usr/bin/nvidia-smi')
        result = `nvidia-smi --query-gpu=power.draw --format=csv,noheader 2>/dev/null`
        return result.strip.to_f.round(1) if result && !result.strip.empty?
      end
      nil
    end

    def init_power_monitoring; end
  end
end
