require "compress/zip"

module Crimson::ENV
  LIBRARY             = Path[::ENV["APPDATA"], "crimson"]
  LIBRARY_BIN_CRYSTAL = LIBRARY_BIN / "crystal.exe"
  LIBRARY_BIN_SHARDS  = LIBRARY_BIN / "shards.exe"

  TARGET_IDENTIFIER  = "windows-x86_64-msvc-unsupported.zip"
  TARGET_BIN_CRYSTAL = Path[::ENV["LOCALAPPDATA"], "Programs", "Crystal", "crystal.exe"]
  TARGET_BIN_SHARDS  = Path[::ENV["LOCALAPPDATA"], "Programs", "Crystal", "shards.exe"]

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
    if File.symlink? LIBRARY_BIN / "crystal.exe"
      File.delete LIBRARY_BIN / "crystal.exe"
    end
    File.symlink path / "crystal.exe", LIBRARY_BIN / "crystal.exe"

    if File.symlink? LIBRARY_BIN / "crystal.pdb"
      File.delete LIBRARY_BIN / "crystal.pdb"
    end
    File.symlink path / "crystal.pdb", LIBRARY_BIN / "crystal.pdb"

    if File.symlink? LIBRARY_BIN / "shards.exe"
      File.delete LIBRARY_BIN / "shards.exe"
    end
    File.symlink path / "shards.exe", LIBRARY_BIN / "shards.exe"
  end

  def self.setup_executable_paths : Nil
    Dir.mkdir_p Path[TARGET_BIN_CRYSTAL].dirname

    if setup_crystal_path?
      File.symlink LIBRARY_BIN / "crystal.exe", TARGET_BIN_CRYSTAL
      File.symlink LIBRARY_BIN / "crystal.pdb", File.join(::ENV["LOCALAPPDATA"], "Programs", "Crystal", "crystal.pdb")
    end

    if setup_shards_path?
      File.symlink LIBRARY_BIN / "shards.exe", TARGET_BIN_SHARDS
    end

    path = String.build do |io|
      Crystal::System::WindowsRegistry.open? LibC::HKEY_CURRENT_USER, "Environment".to_utf16 do |handle|
        io << Crystal::System::WindowsRegistry.get_string handle, "PATH".to_utf16
      end
    end

    if path.empty?
      warn "PATH environment variable not found in system"
      warn "Registry: HKEY_CURRENT_USER\\Environment\\PATH"
      return
    end
  end

  def self.install_dependencies(prompt : Bool) : Nil
  end

  def self.install_additional_dependencies(prompt : Bool) : Nil
    puts "No additional dependencies for this platform"
  end
end
