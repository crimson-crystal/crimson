module Crimson::ENV
  LIBRARY = {% if flag?(:win32) %}
              Path[::ENV["APPDATA"], "crimson"]
            {% else %}
              Path[::ENV["XDG_DATA_HOME"]? || Path.home / ".local" / "share" / "crimson"]
            {% end %}

  CRYSTAL_PATH = LIBRARY / "crystal"
  BIN_PATH     = LIBRARY / "bin"

  TARGET_IDENTIFIER = {% if flag?(:win32) %}
                        "windows-x86_64-msvc-unsupported.zip"
                      {% elsif flag?(:darwin) %}
                        "1-darwin-universal.pkg"
                      {% else %}
                        "1-linux-x86_64.tar.gz"
                      {% end %}

  TARGET_CRYSTAL_BIN = {% if flag?(:win32) %}
                         File.join ::ENV["LOCALAPPDATA"], "Programs", "Crystal", "crystal.exe"
                       {% else %}
                         "/usr/local/bin/crystal"
                       {% end %}

  TARGET_SHARDS_BIN = {% if flag?(:win32) %}
                        File.join ::ENV["LOCALAPPDATA"], "Programs", "Crystal", "shards.exe"
                      {% else %}
                        "/usr/local/bin/shards"
                      {% end %}

  def self.installed?(version : String) : Bool
    Dir.exists? CRYSTAL_PATH / version
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
    Dir.children(CRYSTAL_PATH).select do |child|
      File.directory? CRYSTAL_PATH / child
    end
  end
end
