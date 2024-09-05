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

      add_alias "in"
      add_usage "install [-a|--alias <name>] [-f|--fetch] [-s|--switch] [version]"

      add_argument "version", description: "the version to install"
      add_option 'a', "alias", description: "set the alias of the version", type: :single
      add_option 'd', "default", description: "set the version as default"
      add_option 'f', "fetch", description: "fetch versions from the api"
      add_option 's', "switch", description: "switch the available version on the system"
      add_option "debug"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      version = arguments.get?("version").try &.as_s
      unless version
        verbose { "fetching available versions" }
        version = ENV.get_available_versions(options.has?("fetch"))[0]
      end

      if ENV.installed? version
        error "Crystal version #{version} is already installed"
        command = "crimson switch #{version}".colorize.bold
        fatal "To use it run '#{command}'"
      end

      unless ENV.get_available_versions(false).includes? version
        fatal "Unknown Crystal version: #{version}"
      end

      {% if flag?(:win32) %}
        if SemanticVersion.parse(version) < ENV::MIN_VERSION
          fatal "Crystal is not available on Windows for versions below #{ENV::MIN_VERSION}"
        end
      {% end %}

      installed = false
      path = uninitialized Path
      archive = uninitialized File

      Process.on_terminate do |_|
        if archive
          archive.close rescue nil
          archive.delete rescue nil
        end

        FileUtils.rm_rf path if path && !installed
        STDERR << "\e[?25h"
        exit 1
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
        exit_program
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

      puts "Unpacking archive to destination..."
      begin
        ENV.decompress path, archive.path, options.has? "debug"
      rescue ex
        FileUtils.rm_rf path
        on_error ex
      end

      {% unless flag?(:win32) %}
        puts "Ensuring file permissions"
        if SemanticVersion.parse(version) < ENV::MIN_VERSION
          puts "Resolving legacy paths..."
          File.delete path / "bin" / "crystal"
          File.delete path / "bin" / "shards"
          File.rename path / "lib" / "crystal" / "bin" / "crystal", path / "bin" / "crystal"
          File.rename path / "lib" / "crystal" / "bin" / "shards", path / "bin" / "shards"
        end

        File.chmod path / "bin" / "crystal", 0o755
        File.chmod path / "bin" / "shards", 0o755
      {% end %}

      installed = true

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
        ENV.switch path
        config.current = version

        puts "Switched current Crystal to #{version}"
      end

      puts "Cleaning up processes..."
      config.save
    end
  end
end
