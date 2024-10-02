module Crimson::ENV
  LIBRARY_BIN     = LIBRARY / "bin"
  LIBRARY_CRYSTAL = LIBRARY / "crystal"

  def self.installed?(version : String) : Bool
    Dir.exists? LIBRARY_CRYSTAL / version
  end

  @@versions = [] of String

  def self.get_available_versions(force : Bool) : Array(String)
    return @@versions unless @@versions.empty?
    unless force
      if File.exists? path = LIBRARY / "versions.txt"
        return @@versions = File.read_lines path
      end
    end

    res = Crest.get "https://api.github.com/repos/crystal-lang/crystal/releases"
    data = JSON.parse res.body

    @@versions = data.as_a.map &.["tag_name"].as_s
    File.write LIBRARY / "versions.txt", @@versions.join '\n'

    @@versions
  end

  def self.installed_versions : Array(SemanticVersion)
    Dir.children(LIBRARY_CRYSTAL).select do |child|
      File.directory? LIBRARY_CRYSTAL / child
    end.map { |v| SemanticVersion.parse(v) }.sort!
  end

  {% for name in %w[CRYSTAL SHARDS] %}
    private def self.setup_{{name.downcase.id}}_path? : Bool
      if File.exists? ENV::TARGET_BIN_{{ name.id }}
        if File.symlink? ENV::TARGET_BIN_{{ name.id }}
          link = File.readlink ENV::TARGET_BIN_{{ name.id }}

          link != ENV::LIBRARY_BIN_{{ name.id }}.to_s
        else
          warn "Unknown {{ name.downcase.id }} file at executable path:"
          warn ENV::TARGET_BIN_{{ name.id }}
          warn "Please rename or remove it"

          false
        end
      else
        true
      end
    end
  {% end %}
end

{% if flag?(:win32) %}
  require "./env/win32"
{% elsif flag?(:darwin) %}
  require "./env/darwin"
{% elsif flag?(:unix) %}
  require "./env/linux"
{% else %}
  {% raise "unsupported platform target" %}
{% end %}
