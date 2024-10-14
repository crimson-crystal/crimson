module Crimson
  class Config
    class Error < Exception
      enum Code
        NotFound
        CantParse
        CantSave
      end

      getter code : Code

      def initialize(@code, @cause = nil)
      end
    end

    property current : String?
    property default : String?
    property aliases : Hash(String, String)

    def self.load : self
      File.open ENV::LIBRARY / "crimson.ini" do |file|
        data = INI.parse file

        current = data["current"]?.try &.["version"]
        current = nil if current.try &.empty?
        default = data["current"]?.try &.["default"]
        default = nil if default.try &.empty?
        aliases = data["aliases"]? || {} of String => String

        new current, default, aliases
      end
    rescue File::NotFoundError
      raise Error.new :not_found
    rescue INI::ParseException
      raise Error.new :cant_parse
    end

    def initialize(@current, @default, aliases = nil)
      @aliases = aliases || {} of String => String
    end

    def save : Nil
      File.open ENV::LIBRARY / "crimson.ini", mode: "w" do |file|
        INI.build file, {
          current: {version: @current, default: @default},
          aliases: @aliases,
        }
      end
    rescue ex
      raise Error.new :cant_save, ex
    end
  end
end
