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

      verbose { "checking executables path" }
      unless Dir.exists? bin = ENV::LIBRARY / "bin"
        verbose { "creating executables path" }
        Dir.mkdir_p bin
      end

      verbose { "ensuring paths are linked" }
      if File.symlink? "/usr/local/bin/crystal"
        unless File.real_path("/usr/local/bin/crystal") == (ENV::LIBRARY / "bin" / "crystal").to_s
          verbose { "linking executable paths" }
          link_executables
        end
      else
        verbose { "linking executable paths" }
        link_executables
      end
    end

    private def link_executables : Nil
      begin
        File.symlink ENV::LIBRARY / "bin" / "crystal", "/usr/local/bin/crystal"
      rescue File::Error
        info "Root permissions are required to link executable"
        args = ["ln", "-s", (ENV::LIBRARY / "bin" / "crystal").to_s, "/usr/local/bin/crystal"]
        info "Requested command:"
        info "sudo #{args.join ' '}".colorize.bold.to_s

        status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
        unless status.success?
          error "Failed to link executable path"
          error "Please run the command above after installation is complete"
        end
      end

      begin
        File.symlink ENV::LIBRARY / "bin" / "shards", "/usr/local/bin/shards"
      rescue File::Error
        info "Root permissions are required to link executable"
        args = ["ln", "-s", (ENV::LIBRARY / "bin" / "shards").to_s, "/usr/local/bin/shards"]
        info "Requested command:"
        info "sudo #{args.join ' '}".colorize.bold.to_s

        status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
        unless status.success?
          error "Failed to link executable path"
          error "Please run the command above after installation is complete"
        end
      end
    end
  end
end
