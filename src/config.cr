module Crimson
  class Config
    property current : String?
    property location : String?
    property aliases : Hash(String, String)

    def self.load : self
      File.open ENV::LIBRARY / "crimson.ini" do |file|
        data = INI.parse file

        current = data["current"]?.try &.["version"]
        current = nil if current.try &.empty?
        location = data["current"]?.try &.["location"]
        location = nil if location.try &.empty?
        aliases = data["aliases"]? || {} of String => String

        new current, location, aliases
      end
    end

    def initialize(@current, @location, aliases = nil)
      @aliases = aliases || {} of String => String
    end

    def save : Nil
      File.open ENV::LIBRARY / "crimson.ini", mode: "w" do |file|
        INI.build file, {
          current: {version: @current, location: @location},
          aliases: @aliases,
        }
      end
    end
  end
end
