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
          Internal.link_crystal_executable
        end
      else
        puts "Linking crystal executable path"
        Internal.link_crystal_executable
      end

      if File.symlink? ENV::TARGET_SHARDS_BIN
        link = File.readlink ENV::TARGET_SHARDS_BIN rescue nil
        unless link == (ENV::BIN_PATH / "shards").to_s
          puts "Linking shards executable path"
          Internal.link_shards_executable
        end
      else
        puts "Linking shards executable path"
        Internal.link_shards_executable
      end

      return if options.has? "skip-dependencies"

      puts "Checking dependencies"
      Internal.install_dependencies !options.has?("yes")

      puts "Checking additional dependencies"
      Internal.install_additional_dependencies !options.has?("yes")
    end
  end
end
