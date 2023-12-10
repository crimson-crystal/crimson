module Crimson::Commands
  class Env < Base
    def setup : Nil
      @name = "env"
      @summary = "show the crimson environment"
      @description = <<-DESC
        Shows the current Crimson environment (also available via the 'default' and
        'switch' commands).
        DESC
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load rescue Config.new nil, nil

      stdout << "Library:    " << ENV::LIBRARY << '\n'
      stdout << "Identifier: " << ENV::TARGET_IDENTIFIER.split('.', 2)[0] << '\n'

      stdout << "Current:    "
      if current = config.current
        stdout << current << '\n'
      elsif Process.find_executable "crystal"
        stdout << "system install\n"
      else
        stdout << "none\n"
      end

      stdout << "Default:    "
      if default = config.default
        stdout << default << '\n'
      else
        stdout << "none\n"
      end
    end
  end
end
