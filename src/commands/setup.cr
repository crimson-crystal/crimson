module Crimson::Commands
  class Setup < Base
    def setup : Nil
      @name = "setup"
      @summary = "setup the crimson environment"
    end

    {% if flag?(:win32) %}
      def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
        # TODO
      end
    {% else %}
      def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
        unless Dir.exists? ENV::CRIMSON_LIBRARY
          Dir.mkdir_p ENV::CRIMSON_LIBRARY
        end

        unless Dir.exists? ENV::CRYSTAL_CACHE
          Dir.mkdir_p ENV::CRYSTAL_CACHE
        end

        if path = Process.find_executable "crystal"
          unless File.info(path).type.symlink?
            warn [
              "Crystal appears to be installed without Crimson",
              "Please uninstall it before attempting to install with Crimson",
            ]
          end
        end
      end
    {% end %}
  end
end
