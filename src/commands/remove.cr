module Crimson::Commands
  class Remove < Base
    def setup : Nil
      @name = "remove"
      @summary = "remove a version of Crystal"
      @description = "Removes one or more installed versions of Crystal."

      add_alias "rm"
      add_usage "remove <targets...>"

      add_argument "targets",
        description: "the versions or aliased versions to remove",
        multiple: true,
        required: true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load

      targets = arguments.get("target").as_a
      targets.each do |target|
        if version = config.aliases.delete target
          target = version
        end

        unless ENV.installed? target
          error "Crystal version #{target} is not installed"
          next
        end

        config.current = config.default if config.current == target

        FileUtils.rm_rf ENV::LIBRARY_CRYSTAL / target
      end

      config.save
    end
  end
end
