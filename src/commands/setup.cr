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

      add_option 'v', "verbose"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      unless Dir.exists? ENV::LIBRARY
        puts "creating crimson library path"
        Dir.mkdir_p ENV::LIBRARY
      end

      begin
        _ = Config.load
      rescue File::NotFoundError
        puts "crimson config not found; creating"
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
        puts "creating executables path"
        Dir.mkdir_p ENV::BIN_PATH
      end

      if File.symlink? "/usr/local/bin/crystal"
        realpath = File.realpath "/usr/local/bin/crystal" rescue nil
        unless realpath.try { |p| p == (ENV::BIN_PATH / "crystal").to_s }
          puts "Linking crystal executable path"
          link_executable "crystal"
        end
      else
        puts "Linking crystal executable path"
        link_executable "crystal"
      end

      if File.symlink? "/usr/local/bin/shards"
        realpath = File.realpath "/usr/local/bin/shards" rescue nil
        unless realpath.try { |p| p == (ENV::BIN_PATH / "shards").to_s }
          puts "Linking shards executable path"
          link_executable "shards"
        end
      else
        puts "Linking shards executable path"
        link_executable "shards"
      end
    end

    private def link_executable(name : String) : Nil
      args = {"ln", "-s", (ENV::BIN_PATH / name).to_s, "/usr/local/bin/#{name}"}
      puts "Running command:"
      puts "sudo #{args.join ' '}".colorize.bold.to_s

      err = IO::Memory.new
      status = Process.run "sudo", args, input: :inherit, output: :inherit, error: err

      return unless status.success?
      error err.to_s
      error "Please run the command above after setup is complete"
    end
  end
end
