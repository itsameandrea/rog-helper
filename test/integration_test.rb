# frozen_string_literal: true

require_relative 'test_helper'

class IntegrationTest < Minitest::Test
  def setup
    mock_system_info(power_state: :plugged)
    mock_commands
  end

  def test_changing_profile_restores_slash_state
    with_temp_preferences do
      RogHelper::Commands::Supergfxctl.expects(:set_mode).never
      RogHelper::Commands::Asusctl.expects(:set_profile).with('Performance').once
      RogHelper::Commands::Asusctl.expects(:set_slash_enabled).at_least_once

      app = RogHelper::App.new
      app.instance_variable_set(:@active, 2)
      app.instance_variable_set(:@prof_idx, 2)

      initial_gpu_mode = app.instance_variable_get(:@gpu_mode)
      initial_slash_mode = app.instance_variable_get(:@slash_mode)
      app.send(:apply)
      final_gpu_mode = app.instance_variable_get(:@gpu_mode)
      final_slash_mode = app.instance_variable_get(:@slash_mode)

      assert_equal initial_gpu_mode, final_gpu_mode,
                   'GPU mode should not change when setting profile'
      assert_equal initial_slash_mode, final_slash_mode,
                   'Slash mode should not change when setting profile'
    end
  end

  def test_changing_gpu_mode_does_not_affect_profile
    with_temp_preferences do
      RogHelper::Commands::Asusctl.expects(:set_profile).never
      RogHelper::Commands::Supergfxctl.expects(:set_mode).with('Integrated').once

      app = RogHelper::App.new
      app.instance_variable_set(:@active, 3)
      app.instance_variable_set(:@gpu_idx, 0)

      initial_profile = app.instance_variable_get(:@profile)
      initial_slash_mode = app.instance_variable_get(:@slash_mode)
      app.send(:apply)
      final_profile = app.instance_variable_get(:@profile)
      final_slash_mode = app.instance_variable_get(:@slash_mode)

      assert_equal initial_profile, final_profile,
                   'Profile should not change when setting GPU mode'
      assert_equal initial_slash_mode, final_slash_mode,
                   'Slash mode should not change when setting GPU mode'
    end
  end

  def test_changing_slash_mode_does_not_affect_other_settings
    with_temp_preferences do
      RogHelper::Commands::Asusctl.expects(:set_profile).never
      RogHelper::Commands::Supergfxctl.expects(:set_mode).never
      RogHelper::Commands::Asusctl.expects(:set_slash_enabled).at_least_once

      app = RogHelper::App.new
      app.instance_variable_set(:@active, 5)
      app.instance_variable_set(:@slash_idx, 0)

      initial_gpu_mode = app.instance_variable_get(:@gpu_mode)
      initial_profile = app.instance_variable_get(:@profile)
      initial_fan_preset = app.instance_variable_get(:@fan_preset)

      app.send(:apply)

      assert_equal initial_gpu_mode, app.instance_variable_get(:@gpu_mode)
      assert_equal initial_profile, app.instance_variable_get(:@profile)
      assert_equal initial_fan_preset, app.instance_variable_get(:@fan_preset)
    end
  end

  def test_changing_fan_preset_does_not_affect_other_settings
    with_temp_preferences do
      RogHelper::Commands::Asusctl.expects(:set_profile).never
      RogHelper::Commands::Supergfxctl.expects(:set_mode).never

      app = RogHelper::App.new
      app.instance_variable_set(:@active, 6)
      app.instance_variable_set(:@fan_idx, 0)

      initial_gpu_mode = app.instance_variable_get(:@gpu_mode)
      initial_profile = app.instance_variable_get(:@profile)
      initial_slash_mode = app.instance_variable_get(:@slash_mode)

      app.send(:apply)

      assert_equal initial_gpu_mode, app.instance_variable_get(:@gpu_mode)
      assert_equal initial_profile, app.instance_variable_get(:@profile)
      assert_equal initial_slash_mode, app.instance_variable_get(:@slash_mode)
    end
  end

  def test_profile_is_saved_to_preferences
    with_temp_preferences do
      app = RogHelper::App.new
      app.instance_variable_set(:@active, 2)
      app.instance_variable_set(:@prof_idx, 2)

      app.send(:apply)

      prefs = RogHelper::Preferences.for_state(:plugged)
      assert_equal 'Performance', prefs[:profile]
    end
  end

  def test_gpu_mode_is_saved_to_preferences
    with_temp_preferences do
      app = RogHelper::App.new
      app.instance_variable_set(:@active, 3)
      app.instance_variable_set(:@gpu_idx, 0)

      app.send(:apply)

      prefs = RogHelper::Preferences.for_state(:plugged)
      assert_equal 'Integrated', prefs[:gpu_mode]
    end
  end

  def test_slash_mode_is_saved_to_preferences
    with_temp_preferences do
      app = RogHelper::App.new
      app.instance_variable_set(:@active, 5)
      app.instance_variable_set(:@slash_idx, 0)

      app.send(:apply)

      prefs = RogHelper::Preferences.for_state(:plugged)
      assert_equal 'Off', prefs[:slash_mode]
    end
  end

  def test_fan_preset_is_saved_to_preferences
    with_temp_preferences do
      app = RogHelper::App.new
      app.instance_variable_set(:@active, 6)
      app.instance_variable_set(:@fan_idx, 0)

      app.send(:apply)

      prefs = RogHelper::Preferences.for_state(:plugged)
      assert_equal 'Silent', prefs[:fan_preset]
    end
  end

  def test_preferences_are_separate_for_battery_and_plugged
    with_temp_preferences do
      mock_system_info(power_state: :plugged)

      app = RogHelper::App.new
      app.instance_variable_set(:@active, 2)
      app.instance_variable_set(:@prof_idx, 2)
      app.send(:apply)

      mock_system_info(power_state: :battery)
      app.instance_variable_set(:@power_state, :battery)
      app.instance_variable_set(:@active, 2)
      app.instance_variable_set(:@prof_idx, 0)
      app.send(:apply)

      plugged_prefs = RogHelper::Preferences.for_state(:plugged)
      battery_prefs = RogHelper::Preferences.for_state(:battery)

      assert_equal 'Performance', plugged_prefs[:profile]
      assert_equal 'Quiet', battery_prefs[:profile]
    end
  end

  def test_profile_change_restores_saved_slash_preference
    with_temp_preferences do
      RogHelper::Preferences.save_for_state(:plugged, slash_mode: 'Off')

      RogHelper::Commands::Asusctl.expects(:set_slash_enabled).with(false).at_least_once
      RogHelper::Commands::Asusctl.expects(:set_profile).with('Performance').once

      app = RogHelper::App.new
      app.instance_variable_set(:@active, 2)
      app.instance_variable_set(:@prof_idx, 2)
      app.send(:apply)

      assert_equal 'Off', app.instance_variable_get(:@slash_mode)
    end
  end

  def test_profile_change_preserves_gpu_mode
    with_temp_preferences do
      RogHelper::Preferences.save_for_state(:plugged, gpu_mode: 'Integrated')

      gpu_calls = []
      RogHelper::Commands::Supergfxctl.stubs(:set_mode).with do |m|
        gpu_calls << m
        true
      end

      app = RogHelper::App.new

      gpu_calls.clear

      app.instance_variable_set(:@active, 2)
      app.instance_variable_set(:@prof_idx, 2)
      app.send(:apply)

      assert_empty gpu_calls, 'set_mode should not be called when changing profile'
      assert_equal 'Integrated', app.instance_variable_get(:@gpu_mode)
    end
  end

  def test_profile_change_disables_slash_before_profile_set
    with_temp_preferences do
      call_order = []
      RogHelper::Commands::Asusctl.stubs(:set_slash_enabled).with do |e|
        call_order << [:slash, e]
        true
      end
      RogHelper::Commands::Asusctl.stubs(:set_profile).with do |p|
        call_order << [:profile, p]
        true
      end

      app = RogHelper::App.new
      app.instance_variable_set(:@active, 2)
      app.instance_variable_set(:@prof_idx, 2)
      app.send(:apply)

      first_call = call_order.first
      assert_equal :slash, first_call[0], 'Slash should be disabled before profile change'
      assert_equal false, first_call[1], 'Slash should be disabled (false)'
    end
  end
end
