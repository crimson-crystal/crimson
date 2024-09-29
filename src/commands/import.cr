module Crimson::Commands
  class Import < Base
    def setup : Nil
      @name = "import"

      add_argument "path", required: true
      add_option 'a', "alias", type: :single
      add_option 'd', "default"
      add_option "link"
      add_option 's', "switch"
      add_option 'R', "rename", type: :single
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      {% begin %}
        config = Config.load
        path = Path.new arguments.get("path").as_s
        fatal "Path does not exist or is not a directory" unless Dir.exists? path

        {% if flag?(:win32) %}
          unless File.exists?(path / "bin" / "crystal.exe") && File.exists?(path / "bin" / "crystal.pdb")
            error "Crystal binaries not found"
            fatal "Crystal must be compiled via cmake before importing"
          end

          version = options.get?("rename").try(&.as_s) || begin
            Process.run (path / "bin" / "crystal.exe").to_s, ["version"] do |process|
              process.output.gets('[').as(String).split[1]
            end
          end
        {% else %}
          unless File.exists?(path / "bin" / "crystal") && File.executable?(path / "bin" / "crystal")
            error "Crystal binary not found"
            fatal "Crystal must be compiled via make before importing"
          end

          version = options.get?("rename").try(&.as_s) || begin
            Process.run (path / "bin" / "crystal").to_s, ["version"] do |process|
              process.output.gets('[').as(String).split[1]
            end
          end
        {% end %}

        if ENV.installed? version
          error "Crystal version #{version} is already installed"
          fatal "If you wish to override the set version, rerun with '--version'"
        end

        fatal "Missing 'lib' directory for compiler" unless Dir.exists? path / "lib"
        fatal "Missing 'src' directory for compiler" unless Dir.exists? path / "src"

        Dir.mkdir_p dest = ENV::LIBRARY_CRYSTAL / version

        if options.has? "link"
          puts "Linking library files..."
          File.symlink path / "lib", dest / "lib"

          puts "Linking source files"
          File.symlink path / "src", dest / "src"

          puts "Linking binaries..."
          {% if flag?(:win32) %}
            File.symlink path / "bin" / "crystal.exe", dest / "crystal.exe"
            File.symlink path / "bin" / "crystal.pdb", dest / "crystal.pdb"

            Dir.glob(path / "bin" / "*.dll").each do |dll|
              File.symlink dll, dest / Path[dll].basename
            end
          {% else %}
            File.symlink path / "bin" / "crystal"
          {% end %}

          File.touch path / "LINK", Time.utc
        else
          verbose = options.has? "verbose"
          puts "Copying binaries to destination..."

          {% if flag?(:win32) %}
            File.copy path / "bin" / "crystal.exe", dest / "crystal.exe"
            File.copy path / "bin" / "crystal.pdb", dest / "crystal.pdb"

            Dir.glob(path / "bin" / "*.dll").each do |dll|
              File.copy dll, dest / Path[dll].basename
            end
          {% else %}
            File.copy path / "bin" / "crystal", dest / "crystal"
          {% end %}

          puts "Copying library files to destination..."
          STDERR << "\e[?25l"
          count = 0

          Dir.mkdir_p dest / "lib"
          recurse(root = (path / "lib").to_s) do |entry|
            entry_dest = dest / "lib" / entry.to_s.lchop root
            if verbose
              STDERR << "\e[F" << entry_dest << "\n\n"
            end

            File.copy entry, entry_dest
            count += 1
            STDERR << "\e[2K" << count << " files copied\r"
          end

          STDERR << "\e[F\e[2K"
          puts "#{count} files copied"
          puts "Copying source files to destination..."
          count = 0

          Dir.mkdir_p dest / "src"
          recurse(root = (path / "src").to_s) do |entry|
            entry_dest = dest / "src" / entry.to_s.lchop root
            if verbose
              STDERR << "\e[F" << entry_dest << "\n\n"
            end
            Dir.mkdir_p entry_dest.dirname

            File.copy entry, entry_dest
            count += 1
            STDERR << "\e[2K" << count << " files copied\r"
          end

          STDERR << "\e[F\e[?25h\e[2K"
          puts "#{count} files copied"
        end

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
      {% end %}
    end

    private def recurse(path : Path | String, &block : String -> _) : Nil
      path = Path.new path if path.is_a? String

      if Dir.exists? path
        Dir.each_child path do |child|
          recurse path / child, &block
        end
      else
        block.call path.to_s
      end
    end
  end
end
