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

      path = ENV::LIBRARY / "crystal" / version
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
      archive = File.open(path / "crystal-#{version}.tar.gz", mode: "w")
      verbose { "location: #{archive.path}" }

      source = "https://github.com/crystal-lang/crystal/releases/download/#{version}/crystal-#{version}-#{ENV::HOST_TARGET}.tar.gz"
      puts "Downloading sources..."
      verbose { source }

      Crest.get source do |res|
        IO.copy res.body_io, archive
        archive.close
      end

      puts "Unpacking archive to destination..."
      stderr << "\e[?25l0 files unpacked\r"
      count = size = 0i32

      Compress::Gzip::Reader.open archive.path do |gzip|
        Crystar::Reader.open gzip do |tar|
          tar.each_entry do |entry|
            dest = path / Path[entry.name].parts[1..].join File::SEPARATOR
            if entry.flag == 53 # check directories
              Dir.mkdir_p dest
              next
            end

            File.open dest, mode: "w" do |file|
              IO.copy entry.io, file
              count += 1
              size += entry.size
            end

            stderr << count << " files unpacked (" << size.humanize_bytes << ")\r"
          end
        end
      end

      stderr << "\e[?25h\e[2K"
      puts "#{count} files unpacked (#{size.humanize_bytes})"
      puts "Ensuring file permissions"
      File.chmod path / "bin" / "crystal", 0o755
      File.chmod path / "bin" / "shards", 0o755

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
        if File.symlink? ENV::BIN_PATH / "crystal"
          File.delete ENV::BIN_PATH / "crystal"
        end
        File.symlink path / "bin" / "crystal", ENV::BIN_PATH / "crystal"

        if File.symlink? ENV::BIN_PATH / "shards"
          File.delete ENV::BIN_PATH / "shards"
        end
        File.symlink path / "bin" / "shards", ENV::BIN_PATH / "shards"
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
