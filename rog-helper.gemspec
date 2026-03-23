# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'rog-helper'
  spec.version = '0.1.0'
  spec.authors = ['Andrea']
  spec.email = ['your-email@example.com']

  spec.summary = 'A TUI for managing ASUS ROG laptops'
  spec.description = 'A TUI for managing ASUS ROG laptops with GPU switching, fan curves, battery limits, and power-state aware preferences. Tested on 2025 G14.'
  spec.homepage = 'https://github.com/itsameandrea/rog-helper'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.files = Dir[
    'lib/**/*.rb',
    'bin/rog-helper',
    'README.md',
    'LICENSE'
  ]
  spec.executables = ['rog-helper']

  spec.add_dependency 'bubbles', '~> 0.1'
  spec.add_dependency 'bubbletea', '~> 0.1'
  spec.add_dependency 'lipgloss', '~> 0.1'
end
