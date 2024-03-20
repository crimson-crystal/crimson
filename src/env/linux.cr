require "compress/gzip"
require "crystar"

module Crimson::ENV
  LIBRARY             = Path[::ENV["XDG_DATA_HOME"]? || Path.home / ".local" / "share" / "crimson"]
  LIBRARY_BIN_CRYSTAL = LIBRARY_BIN / "crystal"
  LIBRARY_BIN_SHARDS  = LIBRARY_BIN / "shards"

  MIN_VERSION = SemanticVersion.new 1, 2, 0

  TARGET_IDENTIFIER  = "1-linux-x86_64.tar.gz"
  TARGET_BIN_CRYSTAL = "/usr/local/bin/crystal"
  TARGET_BIN_SHARDS  = "/usr/local/bin/shards"

  def self.decompress(root : Path, path : String, __) : Nil
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
    pkg_cmd = find_package_manager
    unless pkg_cmd
      error "Could not locate the system package manager"
      error "Crystal dependencies must be installed manually"
      return
    end

    deps = get_system_dependencies pkg_cmd[0]
    unless deps
      error "Could not resolve Crystal dependencies for this distribution"
      error "This distribution may require setting up an RPM signing key"
      error "Which cannot be done using Crimson"
      return
    end

    if prompt
      puts "Crystal requires the following dependencies to compile:"
      puts deps.join(' ').colorize.bold
      return unless should_continue?
      puts
    end

    args = pkg_cmd + deps
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
    pkg_cmd = find_package_manager
    unless pkg_cmd
      error "Could not locate the system package manager"
      error "Crystal dependencies must be installed manually"
      return
    end

    deps = get_system_additional_dependencies pkg_cmd[0]
    unless deps
      error "Could not resolve Crystal dependencies for this distribution"
      error "This distribution may require setting up an RPM signing key"
      error "Which cannot be done using Crimson"
      return
    end

    if prompt
      puts "Crystal uses some additional dependencies for compilation"
      puts "These dependencies are not required but may improve compilation:"
      puts deps.join(' ').colorize.bold
      return unless should_continue?
      puts
    end

    args = pkg_cmd + deps
    puts "Running command:"
    puts "sudo #{args.join ' '}".colorize.bold
    puts

    status = Process.run "sudo", args, input: :inherit, output: :inherit, error: :inherit
    puts

    return if status.success?
    error "Please run the command below after the process is complete:"
    puts args.join(' ').colorize.bold
  end

  private def self.find_package_manager : Array(String)?
    info = if File.exists?("/etc/os-release")
             INI.parse File.read "/etc/os-release"
           elsif File.exists?("/usr/lib/os-release")
             INI.parse File.read "/usr/lib/os-release"
           else
             return nil
           end
    return nil unless id_like = info[""]["ID_LIKE"]?

    case id_like.strip '"'
    when "ubuntu", "debian", "ubuntu debian"
      %w[apt-get install -y]
    when "alpine"
      %w[apk add]
    when "centos", "rhel"
      %w[yum install -y]
    when "fedora"
      %w[dnf install -y]
    when "arch"
      %w[pacman -S]
    end
  end

  private def self.get_system_dependencies(tool : String) : Array(String)?
    case tool
    when "apt-get"
      %w[gcc pkg-config libpcre3-dev libpcre2-dev libevent-dev]
    when "apk"
      %w[
        gc gc-dev gcc libgcc
        libatomic_ops llvm16-libs
        libevent libevent-dev libevent-static
        libstdc++ musl musl-dev pcre2 pcre2-dev
      ]
      # when "yum", "dnf"
    when "pacman"
      %w[gc libevent llvm-libs pcre2]
    end
  end

  private def self.get_system_additional_dependencies(tool : String) : Array(String)?
    case tool
    when "apt-get"
      %w[libssl-dev libz-dev libxml2-dev libgmp-dev libyaml-dev]
    when "apk"
      %w[gmp-dev]
      # when "yum", "dnf"
    when "pacman"
      %w[gmp libxml2 libyaml llvm git inetutils]
    end
  end
end
