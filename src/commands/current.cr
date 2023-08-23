module Crimson::Commands
  class Current < Base
    def setup : Nil
      @name = "current"
      @summary = "show the current Crystal version"

      add_usage "current"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      if current = config.current
        info current
      elsif Process.find_executable "crystal"
        info "(system install)"
      else
        info "none"
      end
    end
  end
end
