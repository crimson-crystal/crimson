module Crimson::Commands
  class Switch < Base
    def setup : Nil
      @name = "switch"
      @summary = "switch the current Crystal version"
      @description = <<-DESC
        Manages the available Crystal version on the system. By default this command
        will print the current set Crystal version. Specifying a version or version
        alias will set that as the available version on the system (meaning it will
        switch the Crystal and Shards executables). Specifying a period "." will swap
        the current version with the default version then switch to it. Specifying the
        '--delete' flag will make the current version unavilable on the system.
        DESC

      add_alias "use"
      add_usage "switch"
      add_usage "switch ."
      add_usage "switch <target>"
      add_usage "switch --delete"

      add_argument "target", description: "the version or version alias to switch to"
      add_option 'd', "delete", description: "remove this as"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      if arguments.has? "target"
        on_unknown_options %w[delete] if options.has? "delete"

        target = arguments.get("target").as_s
        if target == "."
          unless default = config.default
            error "No default version set"
            system_exit
          end

          ENV.switch ENV::LIBRARY_CRYSTAL / default
          config.default = config.current
          config.current = default
          config.save
          return
        end

        if version = config.aliases[target]?
          target = version
        end
  
        unless ENV.installed? target
          error "Crystal version #{target} is not installed"
          system_exit
        end
  
        ENV.switch ENV::LIBRARY_CRYSTAL / target
        config.current = target
        config.save
        return
      end

      if options.has? "delete"
        config.current = nil
        config.save
        return
      end

      puts config.current if config.current
    end
  end
end
