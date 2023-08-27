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
        unless path == ENV::TARGET_BIN_CRYSTAL
          warn "Crystal appears to be installed without Crimson"
          warn "Please uninstall it before attempting to install with Crimson"
        end
      end

      unless Dir.exists? ENV::LIBRARY_BIN
        puts "Creating executables path"
        Dir.mkdir_p ENV::LIBRARY_BIN
      end

      if File.exists? ENV::TARGET_BIN_CRYSTAL
        if File.symlink? ENV::TARGET_BIN_CRYSTAL
          link = File.readlink ENV::TARGET_BIN_CRYSTAL
          unless link == ENV::LIBRARY_BIN_CRYSTAL.to_s
            puts "Linking Crystal executable path"
            Internal.link_crystal_executable
          end
        else
          warn "File exists in Crystal executable location:"
          warn ENV::TARGET_BIN_CRYSTAL.to_s
          warn "Please rename or remove it"
        end
      else
        puts "Linking Crystal executable path"
        Internal.link_crystal_executable
      end

      if File.exists? ENV::TARGET_BIN_SHARDS
        if File.symlink? ENV::TARGET_BIN_SHARDS
          link = File.readlink ENV::TARGET_BIN_SHARDS
          unless link == ENV::LIBRARY_BIN_SHARDS.to_s
            puts "Linking Shards executable path"
            Internal.link_shards_executable
          end
        else
          warn "File exists in Shards executable location:"
          warn ENV::TARGET_BIN_SHARDS.to_s
          warn "Please rename or remove it"
        end
      else
        puts "Linking Shards executable path"
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
