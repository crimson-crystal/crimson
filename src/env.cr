module Crimson::ENV
  LIBRARY = {% if flag?(:win32) %}
              Path[::ENV["APPDATA"], "crimson"]
            {% else %}
              Path[::ENV["XDG_DATA_HOME"]? || Path.home / ".local" / "share" / "crimson"]
            {% end %}

  LIBRARY_CRYSTAL = LIBRARY / "crystal"
  LIBRARY_BIN     = LIBRARY / "bin"

  LIBRARY_BIN_CRYSTAL = LIBRARY_BIN / {% if flag?(:win32) %}"crystal.exe"{% else %}"crystal"{% end %}
  LIBRARY_BIN_SHARDS  = LIBRARY_BIN / {% if flag?(:win32) %}"shards.exe"{% else %}"shards"{% end %}

  TARGET_IDENTIFIER = {% if flag?(:win32) %}
                        "windows-x86_64-msvc-unsupported.zip"
                      {% elsif flag?(:darwin) %}
                        "1-darwin-universal.pkg"
                      {% else %}
                        "1-linux-x86_64.tar.gz"
                      {% end %}

  TARGET_BIN_CRYSTAL = {% if flag?(:win32) %}
                         File.join ::ENV["LOCALAPPDATA"], "Programs", "Crystal", "crystal.exe"
                       {% else %}
                         "/usr/local/bin/crystal"
                       {% end %}

  TARGET_BIN_SHARDS = {% if flag?(:win32) %}
                        File.join ::ENV["LOCALAPPDATA"], "Programs", "Crystal", "shards.exe"
                      {% else %}
                        "/usr/local/bin/shards"
                      {% end %}

  def self.installed?(version : String) : Bool
    Dir.exists? LIBRARY_BIN / version
  end

  @@versions = [] of String

  def self.get_available_versions(force : Bool) : Array(String)
    return @@versions unless @@versions.empty?
    unless force
      if File.exists? path = LIBRARY / "versions.txt"
        return @@versions = File.read_lines path
      end
    end

    res = Crest.get "https://crystal-lang.org/api/versions.json"
    data = JSON.parse res.body

    @@versions = data["versions"].as_a.map &.["name"].as_s
    File.write LIBRARY / "versions.txt", @@versions.join '\n'

    @@versions
  end

  def self.get_installed_versions : Array(String)
    Dir.children(LIBRARY_BIN).select do |child|
      File.directory? LIBRARY_BIN / child
    end
  end
end
