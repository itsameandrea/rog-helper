# frozen_string_literal: true

require 'yaml'
require 'fileutils'

module RogHelper
  module Preferences
    CONFIG_DIR = File.expand_path('~/.config/rog-helper')
    CONFIG_FILE = File.join(CONFIG_DIR, 'preferences.yml')

    DEFAULTS = {
      battery: { profile: 'Quiet', gpu_mode: 'Integrated', fan_preset: 'Silent', slash_mode: 'Off' },
      plugged: { profile: 'Performance', gpu_mode: 'Hybrid', fan_preset: 'Performance', slash_mode: 'Static' }
    }.freeze

    module_function

    def load
      return {} unless File.exist?(CONFIG_FILE)

      begin
        saved = YAML.safe_load(File.read(CONFIG_FILE), permitted_classes: [Symbol])
        saved || {}
      rescue StandardError
        {}
      end
    end

    def save(prefs)
      FileUtils.mkdir_p(CONFIG_DIR)
      File.write(CONFIG_FILE, prefs.to_yaml)
    end

    def for_state(state)
      prefs = load
      prefs[state] || {}
    end

    def save_for_state(state, profile: nil, gpu_mode: nil, fan_preset: nil, slash_mode: nil)
      prefs = load
      prefs[state] ||= {}
      prefs[state][:profile] = profile if profile
      prefs[state][:gpu_mode] = gpu_mode if gpu_mode
      prefs[state][:fan_preset] = fan_preset if fan_preset
      prefs[state][:slash_mode] = slash_mode if slash_mode
      save(prefs)
    end
  end
end

class Hash
  def deep_merge(other)
    merge(other) { |_key, old, new| old.is_a?(Hash) && new.is_a?(Hash) ? old.deep_merge(new) : new }
  end
end
