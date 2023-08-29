module Crimson::Commands
  class Install < Base
    def setup : Nil
      @name = "install"
      @summary = "install a version of crystal"
      @description = <<-DESC
        Installs a version of Crystal. If no version is specified, the latest available
        version is selected. Available versions are cached on your system but can be
        fetched from the Crystal API by specifying the '--fetch' option.
        DESC

      add_usage "install [-a|--alias <name>] [-f|--fetch] [-s|--switch] [version]"

      add_argument "version", description: "the version to install"
      add_option 'a', "alias", description: "set the alias of the version", type: :single
      add_option 'd', "default", description: "set the version as default"
      add_option 'f', "fetch", description: "fetch versions from the api"
      add_option 's', "switch", description: "switch the available version on the system"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      version = arguments.get?("version").try &.as_s
      if version
        unless version =~ /\d\.\d\.\d/
          error "Invalid version format (must be major.minor.patch)"
          system_exit
        end
      else
        verbose { "fetching available versions" }
        version = ENV.get_available_versions(options.has?("fetch"))[1]
      end

      if ENV.installed? version
        error "Crystal version #{version} is already installed"
        command = "crimson switch #{version}".colorize.bold
        error "To use it run '#{command}'"
        system_exit
      end

      unless ENV.get_available_versions(false).includes? version
        error "Unknown Crystal version: #{version}"
        system_exit
      end

      path = ENV::LIBRARY_CRYSTAL / version
      puts "Installing Crystal version: #{version}"
      verbose { "ensuring directory: #{path}" }

      begin
        Dir.mkdir_p path
      rescue ex : File::Error
        error "Failed to create directory:"
        error "Location: #{path}"
        error ex.to_s
        system_exit
      end

      verbose { "creating destination file" }
      archive = File.open path / "crystal-#{version}-#{ENV::TARGET_IDENTIFIER}", mode: "w"
      verbose { "location: #{archive.path}" }

      source = "https://github.com/crystal-lang/crystal/releases/download/" \
               "#{version}/crystal-#{version}-#{ENV::TARGET_IDENTIFIER}"

      puts "Downloading sources..."
      verbose { source }

      Crest.get source do |res|
        IO.copy res.body_io, archive
        archive.close
      end

      # TODO: monitoring
      at_exit do
        archive.close unless archive.closed?
        archive.delete
        stderr << "\e[?25h"
      end

      puts "Unpacking archive to destination..."
      Internal.decompress path, archive.path

      {% unless flag?(:win32) %}
        puts "Ensuring file permissions"
        File.chmod path / "bin" / "crystal", 0o755
        File.chmod path / "bin" / "shards", 0o755
      {% end %}

      if value = options.get?("alias").try &.as_s
        puts "Setting version alias"
        if current = config.aliases[value]?
          warn "This will remove the alias from version #{current}"
        end

        config.aliases[value] = version
      end

      if options.has? "default"
        puts "Updating to default version"
        config.default = version
      end

      if options.has? "switch"
        puts "Switching Crystal versions..."
        Internal.switch path
        config.current = version

        puts "Switched current Crystal to #{version}"
      end

      puts "Cleaning up processes..."
      config.save
    ensure
      # TODO: find a way to get this into `at_exit`
      if arc = archive
        arc.close unless arc.closed?
        arc.delete
      end
    end
  end
end
