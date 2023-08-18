module Crimson::ENV
  LIBRARY = {% if flag?(:win32) %}
              Path[::ENV["APPDATA"], "crimson"]
            {% else %}
              Path[::ENV["XDG_DATA_HOME"]? || Path.home / ".local" / "share" / "crimson"]
            {% end %}

  HOST_TARGET = {% if flag?(:win32) %}
                  "windows-x86_64-msvc-unsupported"
                {% elsif flag?(:darwin) %}
                  "1-darwin-universal"
                {% else %}
                  "1-linux-x86_64"
                {% end %}

  def self.has_version?(version : String) : Bool
    Dir.exists? LIBRARY / "crystal" / version
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
