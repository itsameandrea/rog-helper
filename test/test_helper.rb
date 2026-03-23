# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require 'fileutils'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'rog_helper'

module TestHelper
  def with_temp_preferences
    dir = Dir.mktmpdir('rog-helper-test')
    original_config = RogHelper::Preferences.const_get(:CONFIG_DIR)
    original_file = RogHelper::Preferences.const_get(:CONFIG_FILE)

    RogHelper::Preferences.send(:remove_const, :CONFIG_DIR)
    RogHelper::Preferences.send(:remove_const, :CONFIG_FILE)
    RogHelper::Preferences.const_set(:CONFIG_DIR, dir)
    RogHelper::Preferences.const_set(:CONFIG_FILE, File.join(dir, 'preferences.yml'))

    yield
  ensure
    RogHelper::Preferences.send(:remove_const, :CONFIG_DIR)
    RogHelper::Preferences.send(:remove_const, :CONFIG_FILE)
    RogHelper::Preferences.const_set(:CONFIG_DIR, original_config)
    RogHelper::Preferences.const_set(:CONFIG_FILE, original_file)
    FileUtils.rm_rf(dir) if dir
  end

  def mock_system_info(power_state: :plugged)
    RogHelper::SystemInfo.stubs(:power_state).returns(power_state)
    RogHelper::SystemInfo.stubs(:cpu_temp).returns(50.0)
    RogHelper::SystemInfo.stubs(:gpu_temp).returns(45)
    RogHelper::SystemInfo.stubs(:fan_rpm).returns(2000)
    RogHelper::SystemInfo.stubs(:power_draw).returns(10.0)
  end

  def mock_commands
    RogHelper::Commands::Supergfxctl.stubs(:available?).returns(true)
    RogHelper::Commands::Supergfxctl.stubs(:current_mode).returns('Hybrid')
    RogHelper::Commands::Supergfxctl.stubs(:supported_modes).returns(%w[Integrated Hybrid AsusMuxDgpu])

    RogHelper::Commands::Asusctl.stubs(:available?).returns(true)
    RogHelper::Commands::Asusctl.stubs(:current_profile).returns('Balanced')
    RogHelper::Commands::Asusctl.stubs(:list_profiles).returns(%w[Quiet Balanced Performance])
    RogHelper::Commands::Asusctl.stubs(:battery_limit).returns(80)
    RogHelper::Commands::Asusctl.stubs(:slash_modes).returns(%w[Static Bounce Flow Spectrum])
    RogHelper::Commands::Asusctl.stubs(:aura_effects).returns(%w[static breathe rainbow])

    RogHelper::SystemInfo.stubs(:init_power_monitoring)
    RogHelper::SystemInfo.stubs(:cpu_power).returns(nil)
    RogHelper::SystemInfo.stubs(:gpu_power).returns(nil)
  end
end

Minitest::Test.include(TestHelper)
