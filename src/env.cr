module Crimson::ENV
  LIBRARY_BIN     = LIBRARY / "bin"
  LIBRARY_CRYSTAL = LIBRARY / "crystal"

  def self.installed?(version : String) : Bool
    Dir.exists? LIBRARY_CRYSTAL / version
  end

  def self.installed_versions : Array(SemanticVersion)
    Dir.children(LIBRARY_CRYSTAL).select do |child|
      File.directory? LIBRARY_CRYSTAL / child
    end.map { |v| SemanticVersion.parse(v) }.sort!
  end

  def self.fetch_versions : Array(String)
    res = Crest.get "https://api.github.com/repos/crystal-lang/crystal/releases"
    data = JSON.parse res.body

    versions = data.as_a.map &.["tag_name"].as_s
    File.write LIBRARY / "versions.txt", versions.join '\n'

    versions
  end

  def self.fetch_from_version(req : String?) : String?
    if req
      return req if Dir.children(LIBRARY_CRYSTAL).includes?(req)
    end

    available = fetch_versions
    if req
      return req if available.includes? req
    else
      available[0]
    end
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

require "./env/win32"
require "./env/darwin"
require "./env/linux"

{% if !flag?(:win32) && !flag?(:darwin) && !flag?(:linux) %}
  {% raise "unsupported platform target" %}
{% end %}
