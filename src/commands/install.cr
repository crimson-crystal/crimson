module Crimson::Commands
  class Install < Base
    def setup : Nil
      @name = "install"
      @summary = "install a version of crystal"

      add_usage "install [-a|--alias <name>] [-f|--fetch] [-s|--switch] [-v|--verbose] [version]"
      add_argument "version"
      add_option 'a', "alias", type: :single
      add_option 'f', "fetch"
      add_option 's', "switch"
      add_option 'v', "verbose"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      version = arguments.get?("version").try &.as_s
      if version
        unless version =~ /\d\.\d\.\d/
          error "Invalid version format (must be major.minor.patch)"
          system_exit
        end
      else
        verbose { "fetching available versions" }
        version = ENV.get_versions(options.has?("fetch"))[1]
      end

      if ENV.has_version? version
        error "Crystal version #{version} is already installed"
        command = "crimson switch #{version}".colorize.bold
        notice "To use it run '#{command}'"
        system_exit
      end

      unless ENV.get_versions(false).includes? version
        error "Unknown Crystal version: #{version}"
        system_exit
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
        system_exit
      end

      verbose { "creating destination file" }
      archive = File.open(path / "crystal-#{version}.tar.gz", mode: "w")
      verbose { "location: #{archive.path}" }

      source = "https://github.com/crystal-lang/crystal/releases/download/#{version}/crystal-#{version}-#{ENV::HOST_TARGET}.tar.gz"
      info "Downloading sources..."
      verbose { source }

      Crest.get source do |res|
        IO.copy res.body_io, archive
        archive.close
      end

      info "Unpacking archive to destination..."
      stdout << "\e[?25l0 files unpacked\r"
      count = 0i32
      size = 0i64

      Compress::Gzip::Reader.open(archive.path) do |gzip|
        Crystar::Reader.open(gzip) do |tar|
          tar.each_entry do |entry|
            dest = path / Path[entry.name].parts[1..].join(File::SEPARATOR)
            if entry.flag == 53 # check directories
              Dir.mkdir_p dest
              next
            end

            File.open(dest, mode: "w") do |file|
              IO.copy entry.io, file
              count += 1
              size += entry.size
            end

            stdout << "#{count} files unpacked (#{size.humanize_bytes})\r"
          end
        end
      end

      info "#{count} files unpacked (#{size.humanize_bytes})\e[?25h"
    ensure
      if arc = archive
        arc.close unless arc.closed?
        arc.delete
      end
    end
  end
end
