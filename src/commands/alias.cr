module Crimson::Commands
  class Alias < Base
    def setup : Nil
      @name = "alias"
      @summary = "version alias management"

      add_usage "alias [name]"
      add_usage "alias <name> <version>"
      add_usage "alias [-d|--delete] <name>"

      add_argument "name"
      add_argument "version"
      add_option 'd', "delete"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      if arguments.empty?
        config.aliases.each do |name, version|
          stdout << name << " -> " << version << '\n'
        end
        return
      end

      name = arguments.get("name").as_s
      version = arguments.get?("version").try &.as_s

      if options.has? "delete"
        on_unknown_arguments %w[version] if version

        unless config.aliases.delete name
          error "No alias named '#{name}'"
          system_exit
        end
      end

      on_missing_arguments %w[version] unless version

      unless ENV.installed? version
        error "Crystal version #{version} is not installed"
        system_exit
      end

      if current = config.aliases[name]?
        warn "This will remove the alias from version #{current}"
      end

      config.aliases[name] = version
      config.save
    end
  end
end
