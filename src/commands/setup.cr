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

      add_option 's', "skip-dependencies", description: "skip installing external dependencies"
      add_option 'y', "yes", description: "allow all permission prompts"
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
        unless path == ENV::TARGET_CRYSTAL_BIN
          warn "Crystal appears to be installed without Crimson"
          warn "Please uninstall it before attempting to install with Crimson"
        end
      end

      unless Dir.exists? ENV::BIN_PATH
        puts "Creating executables path"
        Dir.mkdir_p ENV::BIN_PATH
      end

      if File.symlink? ENV::TARGET_CRYSTAL_BIN
        link = File.readlink ENV::TARGET_CRYSTAL_BIN rescue nil
        unless link == (ENV::BIN_PATH / "crystal").to_s
          puts "Linking crystal executable path"
          link_executable ENV::TARGET_CRYSTAL_BIN
        end
      else
        puts "Linking crystal executable path"
        link_executable ENV::TARGET_CRYSTAL_BIN
      end

      if File.symlink? ENV::TARGET_SHARDS_BIN
        link = File.readlink ENV::TARGET_SHARDS_BIN rescue nil
        unless link == (ENV::BIN_PATH / "shards").to_s
          puts "Linking shards executable path"
          link_executable ENV::TARGET_SHARDS_BIN
        end
      else
        puts "Linking shards executable path"
        link_executable ENV::TARGET_SHARDS_BIN
      end

      return if options.has? "skip-dependencies"

      puts "Checking external dependencies"
      warn "This may require root permissions"
      install_external_dependencies !options.has?("yes")

      puts "Checking additional dependencies"
      warn "This may require root permissions"
      install_additional_dependencies !options.has?("yes")
    end

    {% if flag?(:win32) %}
      private def link_executable(path : String) : Nil
        return if File.exists? path
        File.symlink (ENV::BIN_PATH / File.basename path).to_s, path
      end

      private def install_external_dependencies(prompt : Bool) : Nil
      end

      private def install_additional_dependencies(prompt : Bool) : Nil
      end
    {% end %}

    {% if flag?(:unix) %}
      private def link_executable(path : String) : Nil
        puts "This may require root permissions"
        args = {"ln", "-s", (ENV::BIN_PATH / File.basename path).to_s, path}
        puts "Running command:"
        puts "sudo #{args.join ' '}".colorize.bold.to_s
        puts

        status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
        puts
        return if status.success?
        error "Please run the command above after setup is complete"
      end

      private def install_external_dependencies(prompt : Bool) : Nil
        args = {"apt-get", "install", "-y", "gcc", "pkg-config", "libpcre3-dev", "libpcre2-dev", "libevent-dev"}
        if prompt
          puts "Crystal requires the following dependencies to compile:"
          puts args[3..].join(' ').colorize.bold
          return unless should_continue?
          puts
        end

        puts "Running command:"
        puts "sudo #{args.join ' '}".colorize.bold
        puts

        status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
        puts
        return if status.success?
        error "Please run the command above after install is complete"
      end

      private def install_additional_dependencies(prompt : Bool) : Nil
        args = {"apt-get", "install", "-y", "libssl-dev", "libz-dev", "libxml2-dev", "libgmp-dev", "libyaml-dev"}
        if prompt
          puts "Crystal uses some additional dependencies for compilation"
          puts "These dependencies are not required but may improve compilation:"
          puts args[3..].join(' ').colorize.bold
          return unless should_continue?
          puts
        end

        puts "Running command:"
        puts "sudo #{args.join ' '}".colorize.bold
        puts

        status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
        puts
        return if status.success?
        error "Please run the command above after install is complete"
      end
    {% end %}

    private def should_continue? : Bool
      loop do
        stdout << "\nDo you want to continue? (y/n) "
        case gets.try &.chomp
        when "y", "ye", "yes"
          return true
        when "n", "no"
          return false
        else
          error "Invalid prompt answer (must be yes or no)"
        end
      end
    end
  end
end
