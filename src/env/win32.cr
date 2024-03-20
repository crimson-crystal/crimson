require "compress/zip"
require "crystal/system/win32/visual_studio"
require "crystal/system/win32/windows_sdk"

module Crimson::ENV
  LIBRARY             = Path[::ENV["APPDATA"], "crimson"]
  LIBRARY_BIN_CRYSTAL = LIBRARY_BIN / "crystal.exe"
  LIBRARY_BIN_SHARDS  = LIBRARY_BIN / "shards.exe"

  MIN_VERSION = SemanticVersion.new 1, 3, 0

  TARGET_IDENTIFIER  = "windows-x86_64-msvc-unsupported.zip"
  TARGET_BIN         = Path[::ENV["LOCALAPPDATA"], "Programs", "Crystal"]
  TARGET_BIN_CRYSTAL = TARGET_BIN / "crystal.exe"
  TARGET_BIN_SHARDS  = TARGET_BIN / "shards.exe"

  HOST_BITS = {{ flag?(:aarch64) ? "ARM64" : flag?(:bits64) ? "x64" : "x86" }}

  def self.decompress(root : Path, path : String, debug : Bool) : Nil
    if debug
      decompress_debug root, path
    else
      decompress root, path
    end
  end

  private def self.decompress(root : Path, path : String) : Nil
    STDERR << "\e[?25l0 files unpacked\r"
    count = size = 0i32

    Compress::Zip::Reader.open path do |zip|
      zip.each_entry do |entry|
        dest = root / entry.filename

        unless Dir.exists? base = File.dirname dest
          Dir.mkdir_p base
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

  private def self.decompress_debug(root : Path, path : String) : Nil
    STDERR << "\e[?25l0 files unpacked\r"
    count = size = 0i32

    Compress::Zip::Reader.open path do |zip|
      STDERR << "\e[2K\n"

      zip.each_entry do |entry|
        dest = root / entry.filename
        STDERR << "\e[F" << dest << "\n\n"

        unless Dir.exists? base = File.dirname dest
          Dir.mkdir_p base
        end

        File.open dest, mode: "w" do |file|
          IO.copy entry.io, file
          count += 1
          size += entry.compressed_size
        end

        STDERR << "\e[2K" << count << " files unpacked (" << size.humanize_bytes << ')'
      end
    end

    STDERR << "\e[F\e[?25h\e[2K"
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
    Dir.mkdir_p TARGET_BIN

    if setup_crystal_path?
      File.symlink LIBRARY_BIN / "crystal.exe", TARGET_BIN_CRYSTAL
      File.symlink LIBRARY_BIN / "crystal.pdb", TARGET_BIN / "crystal.pdb"
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

    return if path.split(';').map(&.chomp('\\')).includes? TARGET_BIN.to_s
    puts "Adding executables to PATH"

    Crystal::System::WindowsRegistry.open? LibC::HKEY_CURRENT_USER, "Environment".to_utf16, LibC::REGSAM::READ | :WRITE do |handle|
      value = Crystal::System::WindowsRegistry.get_string handle, "PATH".to_utf16
      next unless value

      path = value.chomp(';') + ";" + TARGET_BIN.to_s
      status = LibC.RegSetValueExW handle, "PATH".to_utf16, 0, 1, path.to_utf16.to_unsafe.as(UInt8*), path.size * sizeof(UInt16)
      err = WinError.new status

      next if err.error_success?
      raise RuntimeError.from_os_error "RegSetValueExW", err
    end
  end

  def self.install_dependencies(prompt : Bool) : Nil
    if msvc = Crystal::System::VisualStudio.find_latest_msvc_path
      cl = msvc / "bin" / "Host#{HOST_BITS}" / HOST_BITS / "cl.exe"
      return if File.executable? cl
    end

    if prompt
      puts "Crystal requires Microsoft Visual Studio (MSVC) Build Tools"
      puts "to compile programs (available at https://aka.ms/vs/17/release/vs_community.exe)"
      return unless should_continue?
      puts
    end

    puts "Downloading Visual Studio installer"

    exe = File.tempfile "vs_setup.exe" do |file|
      Crest.get "https://aka.ms/vs/17/release/vs_community.exe" do |res|
        IO.copy res.body_io, file
      end
    end

    args = %w[--wait --focusedUi --addProductLang En-us --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64]
    if Crystal::System::WindowsSDK.find_win10_sdk_libpath.nil?
      args << "--add" << "Microsoft.VisualStudio.Component.Windows11SDK.22000"
    end

    puts "Running the Visual Studio installer..."
    puts "This process will continue after the installer is done"

    # BUG: autocasting doesn't work here for some reason
    inherit = Process::Redirect::Inherit
    status = Process.run exe.path, args, input: inherit, output: inherit, error: inherit

    exe.delete
    return if status.success?
    error "Please complete the Visual Studio installation manually:"
    error "https://aka.ms/vs/17/release/vs_community.exe"
  end

  def self.install_additional_dependencies(prompt : Bool) : Nil
    puts "No additional dependencies for this platform"
  end
end

lib LibC
  fun RegSetValueExW(hKey : HKEY, lpValueName : LPWSTR, reserved : DWORD, dwType : DWORD, lpData : BYTE*, cbData : DWORD) : LSTATUS
end
