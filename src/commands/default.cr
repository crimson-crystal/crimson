module Crimson::Commands
  class Default < Base
    def setup : Nil
      @name = "default"
      @summary = "set the default Crystal version"
      @description = <<-DESC
        Manages the default installed Crystal version. Specifying a version or version
        alias will set that version as the default. Specifying the '--delete' flag will
        remove the version as default.
        DESC

      add_usage "default"
      add_usage "default [target]"
      add_usage "default --delete"

      add_argument "target", description: "the version or alias to set"
      add_option 'd', "delete", description: "remove this as default"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      if arguments.has? "target"
        on_unknown_options %w[delete] if options.has? "delete"

        target = arguments.get("target").as_s
        if version = config.aliases[target]?
          target = version
        end

        fatal "Crystal version #{target} is not installed" unless ENV.installed? target

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
