module Crimson::Commands
  class Switch < Base
    def setup : Nil
      @name = "switch"
      @summary = "switch the current Crystal version"

      add_usage "switch [-v|--verbose] <version>"
      add_usage "switch [-v|--verbose] <alias>"

      add_argument "target", required: true
      add_option 'v', "verbose"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load
      target = arguments.get("target").as_s

      unless target =~ /\d\.\d\.\d/
        if version = config.aliases[target]?
          target = version
        else
          error "Invalid version format (must be major.minor.patch)"
          system_exit
        end
      end

      unless ENV.installed? target
        error "Crystal version #{target} is not installed"
        system_exit
      end

      root = ENV::LIBRARY / "crystal" / target

      if File.symlink? ENV::BIN_PATH / "crystal"
        File.delete ENV::BIN_PATH / "crystal"
      end
      File.symlink root / "bin" / "crystal", ENV::BIN_PATH / "crystal"

      if File.symlink? ENV::BIN_PATH / "shards"
        File.delete ENV::BIN_PATH / "shards"
      end
      File.symlink root / "bin" / "shards", ENV::BIN_PATH / "shards"

      config.current = target
      config.save
    end
  end
end
