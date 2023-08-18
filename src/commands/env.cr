module Crimson::Commands
  class Env < Base
    def setup : Nil
      @name = "env"
      @summary = "show the crimson environment"

      add_usage "env"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = begin
        Config.load
      rescue File::NotFoundError
        warn "Configuration file not found"
        Config.new nil
      rescue YAML::ParseException
        warn "Failed to parse configuration file"
        Config.new nil
      end

      stdout << "Library:   " << ENV::LIBRARY << '\n'
      stdout << "Location:  " << ENV::LIBRARY / "config.yml" << '\n'
      stdout << "Target:    " << ENV::HOST_TARGET << '\n'
      stdout << "Current:   "

      if current = config.current
        stdout << current << '\n'
      elsif Process.find_executable "crystal"
        stdout << "(system install)\n"
      else
        stdout << "none\n"
      end

      stdout << "Installed: "
      if config.installed.empty?
        stdout << "none\n"
      else
        config.installed.each { |version| stdout << "\n- " << version }
        stdout << '\n'
      end
    end
  end
end
