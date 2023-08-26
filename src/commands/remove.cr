module Crimson::Commands
  class Remove < Base
    def setup : Nil
      @name = "remove"
      @summary = "remove a version of Crystal"
      @description = "Removes an installed version of Crystal."

      add_alias "rm"
      add_usage "remove <target>"

      add_argument "target", description: "the version or alias version to remove", required: true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      target = arguments.get("target").as_s
      if version = config.aliases.delete target
        target = version
      end

      unless ENV.installed? target
        error "Crystal version #{target} is not installed"
        system_exit
      end

      config.current = config.default if config.current == target
      config.save

      FileUtils.rm_rf ENV::CRYSTAL_PATH / target
    end
  end
end
