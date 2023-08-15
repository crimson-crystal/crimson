module Crimson::Commands
  class Version < Base
    def setup : Nil
      @name = "version"
      @summary = "get version information"
      @description = "Gets the version information about Crimson."

      add_usage "version"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout << "crimson version " << Crimson::VERSION
      stdout << " [" << Crimson::BUILD_HASH << "] ("
      stdout << Crimson::BUILD_DATE << ")\n"
    end
  end
end
