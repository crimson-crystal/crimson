require "compress/zip"

module Crimson::Internal
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

  def self.link_crystal_executable : Nil
    File.symlink ENV::LIBRARY_BIN / "crystal.exe", ENV::TARGET_BIN_CRYSTAL
    File.symlink ENV::LIBRARY_BIN / "crystal.pdb", File.join(::ENV["LOCALAPPDATA"], "Programs", "Crystal", "crystal.pdb")
  end

  def self.link_shards_executable : Nil
    File.symlink ENV::LIBRARY_BIN / "shards.exe", ENV::TARGET_BIN_SHARDS
  end

  def self.install_dependencies(prompt : Bool) : Nil
  end

  def self.install_additional_dependencies(prompt : Bool) : Nil
    puts "No additional dependencies for this platform"
  end
end