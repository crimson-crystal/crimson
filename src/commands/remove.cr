module Crimson::Commands
  class Remove < Base
    def setup : Nil
      @name = "remove"
      @summary = "remove a version of Crystal"

      add_argument "target", required: true
      add_option 'v', "verbose"
    end

    # NOTE: config is saved preemtively because `at_exit` doesn't work
    # ref:  https://github.com/crystal-lang/crystal/issues/8687
    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load
      target = arguments.get("target").as_s

      unless target =~ /\d\.\d\.\d/
        if version = config.aliases.delete target
          target = version
        else
          error "Invalid version format (must be major.minor.patch)"
          system_exit
        end
      end

      config.current = nil if config.current == target
      config.save

      unless ENV.installed? target
        error "Crystal version #{target} is not installed"
        system_exit
      end

      FileUtils.rm_rf ENV::LIBRARY / "crystal" / target
    end
  end
end