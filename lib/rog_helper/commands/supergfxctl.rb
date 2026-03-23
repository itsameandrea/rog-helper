# frozen_string_literal: true

module RogHelper
  module Commands
    module Supergfxctl
      module_function

      def available?
        system('which supergfxctl > /dev/null 2>&1')
      end

      def current_mode
        `supergfxctl --get 2>/dev/null`.strip
      end

      def status
        `supergfxctl --status 2>/dev/null`.strip
      end

      def supported_modes
        result = `supergfxctl --supported 2>/dev/null`
        result.scan(/\[(\w+(?:,\s*\w+)*)\]/).flatten.flat_map { |s| s.split(', ').map(&:strip) }
      end

      def set_mode(mode)
        system("supergfxctl --mode #{mode}")
      end
    end
  end
end
