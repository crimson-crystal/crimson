module Crimson::Commands
  class List < Base
    def setup : Nil
      @name = "list"
      @summary = "list installed Crystal versions"

      add_usage "list [-a|--alias] [-p|--path]"

      add_option 'a', "alias", description: "include the version alias"
      add_option 'p', "path", description: "include the compiler path"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      installed = ENV.get_installed_versions
      return if installed.empty?

      unless options.has?("alias") || options.has?("path")
        installed.each { |version| stdout << "• " << version << '\n' }
        return
      end

      config = Config.load
      aliases = config.aliases.invert

      stdout << "Version"
      stdout << " " * (installed.max_of &.size)

      if options.has? "alias"
        stdout << "Alias"
        max = config.aliases.keys.max_of &.size
        stdout << " " * max
      end

      if options.has? "path"
        stdout << "Path"
      end

      stdout << '\n'
      installed.each do |version|
        stdout << version << "  "

        if options.has? "alias"
          config.aliases.fetch(version, "none").ljust stdout, 5
          stdout << ' '
        end

        stdout << '\n'
      end
    rescue File::NotFoundError
      error "Crimson config not found"
      error "Run '#{"crimson setup".colorize.bold}' to create"
    rescue INI::ParseException
      error "Cannot parse Crimson config"
      error "Run '#{"crimson setup".colorize.bold}' to restore"
      system_exit
    end
  end
end
