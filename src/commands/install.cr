module Crimson::Commands
  class Install < Base
    def setup : Nil
      @name = "install"
      @summary = "install a version of crystal"

      add_usage "install [-d|--default] [-f|--force] [-v|--verbose] [version]"
      add_argument "version"
      add_option 'd', "default"
      add_option 'f', "force"
      add_option 'v', "verbose"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      version = arguments.get?("version").try &.as_s
      unless version
        verbose { "fetching available versions" }
        version = ENV.get_versions(options.has?("force"))[1]
      end

      if ENV.has_version? version
        error "Crystal version #{version} is already installed"
        error "To use it run 'crimson switch #{version}'"
        return
      end

      unless ENV.get_versions(false).includes? version
        error "Unknown Crystal version: #{version}"
        return
      end

      path = ENV::CRIMSON_LIBRARY / "crystal" / version
      info "Installing Crystal version: #{version}"
      verbose { "ensuring directory: #{path}" }

      begin
        Dir.mkdir_p path
      rescue ex : File::Error
        error "Failed to create directory:"
        error "Location: #{path}"
        error ex.to_s
        return
      end
    end
  end
end
