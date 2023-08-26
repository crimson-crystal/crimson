require "compress/gzip"
require "crystar"

module Crimson::Internal
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
    if File.symlink? ENV::BIN_PATH / "crystal"
      File.delete ENV::BIN_PATH / "crystal"
    end
    File.symlink path / "bin" / "crystal", ENV::BIN_PATH / "crystal"

    if File.symlink? ENV::BIN_PATH / "shards"
      File.delete ENV::BIN_PATH / "shards"
    end
    File.symlink path / "bin" / "shards", ENV::BIN_PATH / "shards"
  end

  def self.link_crystal_executable : Nil
    args = {"ln", "-s", (ENV::BIN_PATH / "crystal").to_s, ENV::TARGET_CRYSTAL_BIN}
    puts "Running command:"
    puts "sudo #{args.join ' '}".colorize.bold
    puts

    status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
    puts

    return if status.success?
    error "Please run the command below after the process is complete:"
    puts args.join(' ').colorize.bold
  end

  def self.link_shards_executable : Nil
    args = {"ln", "-s", (ENV::BIN_PATH / "crystal").to_s, ENV::TARGET_SHARDS_BIN}
    puts "Running command:"
    puts "sudo #{args.join ' '}".colorize.bold
    puts

    status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
    puts

    return if status.success?
    error "Please run the command below after the process is complete:"
    puts args.join(' ').colorize.bold
  end

  def self.install_dependencies(prompt : Bool) : Nil
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
    error "Please run the command below after the process is complete:"
    puts args.join(' ').colorize.bold
  end

  def self.install_additional_dependencies(prompt : Bool) : Nil
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
    error "Please run the command below after the process is complete:"
    puts args.join(' ').colorize.bold
  end
end
