# frozen_string_literal: true

require 'bubbletea'
require 'lipgloss'
require 'bubbles'

module RogHelper
end

require_relative 'rog_helper/commands/asusctl'
require_relative 'rog_helper/commands/supergfxctl'
require_relative 'rog_helper/system_info'
require_relative 'rog_helper/styles'
require_relative 'rog_helper/models/dashboard'
require_relative 'rog_helper/models/gpu'
require_relative 'rog_helper/models/fans'
require_relative 'rog_helper/models/profiles'
require_relative 'rog_helper/models/battery'
require_relative 'rog_helper/models/keyboard'
require_relative 'rog_helper/models/panel'
require_relative 'rog_helper/app'
