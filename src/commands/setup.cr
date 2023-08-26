module Crimson::Commands
  class Setup < Base
    def setup : Nil
      @name = "setup"
      @summary = "setup the crimson environment"
      @description = {% if flag?(:win32) %}
                       <<-DESC
                        Runs the setup process for the Crimson environment and configurations. In order
                        to manage Crystal versions, Crimson will update the PATH environment variable
                        for the current user's environment with the path to Crimson's bin/executable
                        path. This may require elevated permissions which you will be prompted for
                        during setup.
                        DESC
                     {% else %}
                       <<-DESC
                        Runs the setup process for the Crimson environment and configurations. In order
                        to manage Crystal versions, Crimson will attempt to link its bin/executable path
                        to the current user's local bin path (usually at '/usr/local/bin'). This may
                        require root permissions which you will be prompted for during setup.
                        DESC
                     {% end %}
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      unless Dir.exists? ENV::LIBRARY
        puts "Creating crimson library path"
        Dir.mkdir_p ENV::LIBRARY
      end

      begin
        _ = Config.load
      rescue File::NotFoundError
        puts "Crimson config not found; creating"
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

      unless Dir.exists? ENV::BIN_PATH
        puts "Creating executables path"
        Dir.mkdir_p ENV::BIN_PATH
      end

      if File.symlink? "/usr/local/bin/crystal"
        link = File.readlink "/usr/local/bin/crystal" rescue nil
        unless link == (ENV::BIN_PATH / "crystal").to_s
          puts "Linking crystal executable path"
          puts "This may require root permissions"
          link_executable "crystal"
        end
      else
        puts "Linking crystal executable path"
        puts "This may require root permissions"
        link_executable "crystal"
      end

      if File.symlink? "/usr/local/bin/shards"
        link = File.readlink "/usr/local/bin/shards" rescue nil
        unless link == (ENV::BIN_PATH / "shards").to_s
          puts "Linking shards executable path"
          puts "This may require root permissions"
          link_executable "shards"
        end
      else
        puts "Linking shards executable path"
        puts "This may require root permissions"
        link_executable "shards"
      end

      # TODO: security - must be behind a --yes flag
      puts "Installing external dependencies"
      puts "This may require root permissions"
      install_external_dependencies

      puts "Installing additional dependencies"
      puts "These are not required for Crystal and can be skipped"
      install_additional_dependencies
    end

    private def link_executable(name : String) : Nil
      args = {"ln", "-s", (ENV::BIN_PATH / name).to_s, "/usr/local/bin/#{name}"}
      puts "Running command:"
      puts "sudo #{args.join ' '}".colorize.bold.to_s
      puts

      status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
      puts
      return if status.success?
      error "Please run the command above after setup is complete"
    end

    private def install_external_dependencies : Nil
      args = {"apt-get", "install", "-y", "gcc", "pkg-config", "libpcre3-dev", "libpcre2-dev", "libevent-dev"}
      puts "Running command:"
      puts "sudo #{args.join ' '}".colorize.bold
      puts

      status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
      puts
      return if status.success?
      error "Please run the command above after install is complete"
    end

    private def install_additional_dependencies : Nil
      args = {"apt-get", "install", "-y", "libssl-dev", "libz-dev", "libxml2-dev", "libgmp-dev", "libyaml-dev"}
      puts "Running command:"
      puts "sudo #{args.join ' '}".colorize.bold
      puts

      status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
      puts
      return if status.success?
      error "Please run the command above after install is complete"
    end
  end
end
