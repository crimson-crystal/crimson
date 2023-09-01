require "compress/zip"

module Crimson::Internal
  private REG_KEY_READ = 131097u32
  private REG_KEY_WRITE = 131078u32

  def self.decompress(root : Path, path : String) : Nil
    STDERR << "\e[?25l0 files unpacked\r"
    count = size = 0i32

    Compress::Zip::Reader.open path do |zip|
      zip.each_entry do |entry|
        dest = root / entry.filename
        if entry.dir?
          Dir.mkdir_p dest
          next
        end

        File.open dest, mode: "w" do |file|
          IO.copy entry.io, file
          count += 1
          size += entry.compressed_size
        end

        STDERR << count << " files unpacked (" << size.humanize_bytes << ")\r"
      end
    end

    STDERR << "\e[?25h\e[2K"
    puts "#{count} files unpacked (#{size.humanize_bytes})"
  end

  def self.switch(path : Path) : Nil
    if File.symlink? ENV::LIBRARY_BIN / "crystal.exe"
      File.delete ENV::LIBRARY_BIN / "crystal.exe"
    end
    File.symlink path / "crystal.exe", ENV::LIBRARY_BIN / "crystal.exe"

    if File.symlink? ENV::LIBRARY_BIN / "crystal.pdb"
      File.delete ENV::LIBRARY_BIN / "crystal.pdb"
    end
    File.symlink path / "crystal.pdb", ENV::LIBRARY_BIN / "crystal.pdb"

    if File.symlink? ENV::LIBRARY_BIN / "shards.exe"
      File.delete ENV::LIBRARY_BIN / "shards.exe"
    end
    File.symlink path / "shards.exe", ENV::LIBRARY_BIN / "shards.exe"
  end

  def self.setup_executable_paths : Nil
    Dir.mkdir_p Path[ENV::TARGET_BIN_CRYSTAL].dirname

    if setup_crystal_path?
      File.symlink ENV::LIBRARY_BIN / "crystal.exe", ENV::TARGET_BIN_CRYSTAL
      File.symlink ENV::LIBRARY_BIN / "crystal.pdb", File.join(::ENV["LOCALAPPDATA"], "Programs", "Crystal", "crystal.pdb")
    end

    if setup_shards_path?
      File.symlink ENV::LIBRARY_BIN / "shards.exe", ENV::TARGET_BIN_SHARDS
    end

    err = LibC::RegOpenKeyExW(LibC::HKEY_CURRENT_USER, "Environment".to_wstr, 0, REG_KEY_READ | REG_KEY_WRITE, out hkey)
    unless err == 0
      puts "RegOpenKeyExW"
      pp! err
      return
    end

    err = LibC::RegQueryValueExW(hkey, "PATH".to_wstr, Pointer(Void).null, :none, out data, 2048.to_unsafe)
    unless err == 0
      puts "RegQueryValueExW"
      pp! err
      return
    end
  end

  def self.install_dependencies(prompt : Bool) : Nil
  end

  def self.install_additional_dependencies(prompt : Bool) : Nil
    puts "No additional dependencies for this platform"
  end
end
