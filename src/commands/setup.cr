module Crimson::Commands
  class Setup < Base
    def setup : Nil
      @name = "setup"
      @summary = "setup the crimson environment"

      add_option 'v', "verbose"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      verbose { "checking crimson library path" }
      unless Dir.exists? ENV::LIBRARY
        verbose { "creating crimson library path" }
        Dir.mkdir_p ENV::LIBRARY
      end

      begin
        verbose { "checking crimson config file" }
        _ = Config.load
      rescue File::NotFoundError
        verbose { "crimson config not found; creating" }
        Config.new(nil, nil).save
      rescue INI::ParseException
        warn "Config is in an invalid format; overwriting"
        Config.new(nil, nil).save
      end

      if path = Process.find_executable "crystal"
        unless File.info(path).type.symlink?
          warn "Crystal appears to be installed without Crimson"
          warn "Please uninstall it before attempting to install with Crimson"
        end
      end
    end
  end
end
