module Crimson::Commands
  class Remove < Base
    def setup : Nil
      @name = "remove"
      @summary = "remove a version of Crystal"

      add_argument "version", required: true
      add_option 'v', "verbose"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      version = arguments.get("version").as_s
      path = ENV::LIBRARY / "crystal" / version

      unless Dir.exists? path
        error "Crystal version #{version} is not installed"
        system_exit
      end

      FileUtils.rm_rf path
    end
  end
end
