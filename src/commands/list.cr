module Crimson::Commands
  class List < Base
    private struct Result
      getter version : String
      getter alias : String?
      getter path : String?

      def initialize(@version, @alias, @path)
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
      config = Config.load
      installed = ENV.installed_versions.reverse!
      return if installed.empty?

      unless options.has?("alias") || options.has?("path")
        installed.each { |version| puts version }
        return
      end

      if options.has? "alias"
        aliases = config.aliases.invert
      end

      with_path = options.has? "path"
      max_name = max_alias = 0
      results = [] of Result

      installed.each do |version|
        version = version.to_s
        max_name = version.size if version.size > max_name
        if alias_name = aliases.try &.[version]?
          max_alias = alias_name.size if alias_name.size > max_alias
        end

        results << Result.new(
          version,
          alias_name,
          with_path ? (ENV::LIBRARY_CRYSTAL / version).to_s : nil,
        )
      end

      max_name += 2
      max_alias += 2 if options.has? "alias"

      results.each do |result|
        result.version.ljust stdout, max_name
        stdout << result.alias

        if with_path
          if alias_name = result.alias
            stdout << " " * (max_alias - alias_name.size)
          else
            stdout << " " * max_alias
          end
          stdout << result.path
        end
        stdout << '\n'
      end
    end
  end
end
