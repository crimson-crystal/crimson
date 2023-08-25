module Crimson::Commands
  class Default < Base
    def setup : Nil
      @name = "default"
      @summary = "set the default Crystal version"

      add_argument "target"
      add_option 'd', "delete"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      if arguments.has? "target"
        on_unknown_options %w[delete] if options.has? "delete"

        target = arguments.get("target").as_s
        if version = config.aliases[target]?
          target = version
        end

        unless ENV.installed? target
          error "Crystal version #{target} is not installed"
          system_exit
        end

        config.default = target
        config.save
        return
      end

      if options.has? "delete"
        config.default = nil
        config.save
        return
      end

      puts config.default if config.default
    end
  end
end
