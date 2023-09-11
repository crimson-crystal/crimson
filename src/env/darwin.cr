require "compress/gzip"
require "crystar"

module Crimson::ENV
  LIBRARY             = Path[::ENV["XDG_DATA_HOME"]? || Path.home / ".local" / "share" / "crimson"]
  LIBRARY_BIN_CRYSTAL = LIBRARY_BIN / "crystal"
  LIBRARY_BIN_SHARDS  = LIBRARY_BIN / "shards"

  MIN_VERSION = SemanticVersion.new 1, 2, 0

  TARGET_IDENTIFIER  = "1-darwin-universal.tar.gz"
  TARGET_BIN_CRYSTAL = "/usr/local/bin/crystal"
  TARGET_BIN_SHARDS  = "/usr/local/bin/shards"

  def self.decompress(root : Path, path : String) : Nil
    STDERR << "\e[?25l0 files unpacked\r"
    count = size = 0i32

    Compress::Gzip::Reader.open path do |gzip|
      Crystar::Reader.open gzip do |tar|
        tar.each_entry do |entry|
          dest = root / Path[entry.name].parts[1..].join File::SEPARATOR
          if entry.flag == 53 # check directories
            Dir.mkdir_p dest
            next
          end

          File.open dest, mode: "w" do |file|
            IO.copy entry.io, file
            count += 1
            size += entry.size
          end

          STDERR << count << " files unpacked (" << size.humanize_bytes << ")\r"
        end
      end
    end

    STDERR << "\e[?25h\e[2K"
    puts "#{count} files unpacked (#{size.humanize_bytes})"
  end

  def self.switch(path : Path) : Nil
    if File.symlink? LIBRARY_BIN / "crystal"
      File.delete LIBRARY_BIN / "crystal"
    end
    File.symlink path / "bin" / "crystal", LIBRARY_BIN / "crystal"

    if File.symlink? LIBRARY_BIN / "shards"
      File.delete LIBRARY_BIN / "shards"
    end
    File.symlink path / "bin" / "shards", LIBRARY_BIN / "shards"
  end

  def self.setup_executable_paths : Nil
    if setup_crystal_path?
      args = {"ln", "-s", LIBRARY_BIN_CRYSTAL.to_s, TARGET_BIN_CRYSTAL}
      puts "Running command:"
      puts "sudo #{args.join ' '}".colorize.bold
      puts

      status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
      puts

      unless status.success?
        error "Please run the command above after the process is complete"
        puts
      end
    end

    return unless setup_shards_path?
    args = {"ln", "-s", LIBRARY_BIN_SHARDS.to_s, TARGET_BIN_SHARDS}
    puts "Running command:"
    puts "sudo #{args.join ' '}".colorize.bold
    puts

    status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
    puts

    return if status.success?
    error "Please run the command above after the process is complete"
    puts
  end

  def self.install_dependencies(prompt : Bool) : Nil
    unless Process.find_executable "brew"
      error "Could not locate the system package manager"
      error "Crystal dependencies must be installed manually"
      return
    end

    args = {"install", "bdw-gc", "gmp", "libevent", "libyaml", "llvm@15", "openssl@3", "pcre2", "pkg-config"}

    if prompt
      puts "Crystal requires the following dependencies to compile:"
      puts args[1..].join(' ').colorize.bold
      return unless should_continue?
      puts
    end

    puts "Running command:"
    puts "brew #{args.join ' '}".colorize.bold
    puts

    status = Process.run "brew", args, input: :inherit, output: :inherit, error: :inherit
    puts

    return if status.success?
    error "Please run the command below after the process is complete:"
    puts args.join(' ').colorize.bold
  end

  def self.install_additional_dependencies(prompt : Bool) : Nil
    puts "No additional dependencies for this platform"
  end
end
