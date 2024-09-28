module Crimson::Commands
  class List < Base
    private class Result
      getter version : String
      property! alias : String
      property path : String?

      def initialize(@version)
      end
    end

    def setup : Nil
      @name = "list"
      @summary = "list installed Crystal versions"
      @description = "Lists the installed Crystal versions."

      add_alias "ls"
      add_usage "list [-a|--alias] [-p|--path]"

      add_option 'a', "alias", description: "include the version alias"
      add_option 'p', "path", description: "include the compiler path"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      installed = ENV.get_installed_versions.reverse!
      return if installed.empty?

      unless options.has?("alias") || options.has?("path")
        installed.each { |version| stdout << version << '\n' }
        return
      end

      config = Config.load
      _alias = options.has? "alias"
      max_alias = 0
      path = options.has? "path"
      results = installed.map { |version| Result.new version.to_s }

      if _alias && !config.aliases.empty?
        aliases = config.aliases.invert
        if path
          max_alias = 2 + aliases.values.max_of &.size
        end

        results.each do |result|
          if name = aliases[result.version]?
            result.alias = name
          end
        end
      end

      if path
        results.each do |result|
          result.path = (ENV::LIBRARY_CRYSTAL / result.version).to_s
        end
      end

      results.each do |result|
        result.version.ljust stdout, 8
        stdout << result.alias if result.alias?
        if path
          if _alias
            if result.alias?
              stdout << " " * (max_alias - result.alias.size)
            else
              stdout << " " * max_alias
            end
          end
          stdout << result.path
        end
        stdout << '\n'
      end
    rescue File::NotFoundError
      error "Crimson config not found"
      fatal "Run '#{"crimson setup".colorize.bold}' to create"
    rescue INI::ParseException
      error "Cannot parse Crimson config"
      fatal "Run '#{"crimson setup".colorize.bold}' to restore"
    end
  end
end
