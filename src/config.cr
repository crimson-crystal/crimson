module Crimson
  class Config
    include YAML::Serializable

    property current : String?
    property installed : Array(String) = [] of String
    property aliases : Hash(String, String) = {} of String => String

    def self.load : self
      from_yaml File.read ENV::LIBRARY / "config.yml"
    end

    def initialize(@current)
    end

    def save : Nil
      File.write ENV::LIBRARY / "config.yml", to_yaml
    end
  end
end
