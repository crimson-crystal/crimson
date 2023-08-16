module Crimson::ENV
  CRIMSON_LIBRARY = {% if flag?(:win32) %}
                      Path[::ENV["APPDATA"], "crimson"]
                    {% else %}
                      begin
                        if data = ::ENV["XDG_DATA_HOME"]?
                          Path[data, "crimson"]
                        else
                          Path.home / ".local" / "share" / "crimson"
                        end
                      end
                    {% end %}

  CRYSTAL_CACHE = {% if flag?(:win32) %}
                    Path[::ENV["LOCALAPPDATA"], "crystal"]
                  {% else %}
                    Path.home / ".cache" / "crystal"
                  {% end %}

  CRYSTAL_LIBRARY = {% if flag?(:win32) %}
                      Path[::ENV["LOCALAPPDATA"], "Programs", "Crystal"]
                    {% else %}
                      Path["usr", "lib", "crystal"]
                    {% end %}

  HOST_TARGET = {% if flag?(:win32) %}
                  "windows-x86_64-msvc-unsupported"
                {% elsif flag?(:darwin) %}
                  "1-darwin-universal"
                {% else %}
                  "1-linux-x86_64"
                {% end %}

  def self.has_version?(version : String) : Bool
    Dir.exists? CRIMSON_LIBRARY / "crystal" / version
  end

  @@versions = [] of String

  # TODO: cache the response in file system
  def self.get_versions(force : Bool) : Array(String)
    return @@versions unless @@versions.empty?

    res = Crest.get "https://crystal-lang.org/api/versions.json"
    data = JSON.parse res.body

    @@versions = data["versions"].as_a.map &.["name"].as_s
  end
end
