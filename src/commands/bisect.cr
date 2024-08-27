require "wait_group"

module Crimson::Commands
  class Bisect < Base
    def setup : Nil
      @name = "bisect"

      add_alias "bi"
      add_usage "bisect [-F|--fail-first] [--from <version>] [-o|--order <asc|desc|random>] [--to <version>] <args>"

      add_argument "args", multiple: true, required: true
      add_option 'F', "fail-first"
      add_option "from", type: :single
      add_option 'o', "order", type: :single
      add_option "to", type: :single
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load
      initial = config.current || config.default
      versions = ENV.get_installed_versions.sort_by { |v| SemanticVersion.parse(v) }
      system_exit if versions.empty?

      if from = options.get?("from").try &.as_s
        from = SemanticVersion.parse from
        versions.reject! { |v| SemanticVersion.parse(v) < from }
      end

      if to = options.get?("to").try &.as_s
        to = SemanticVersion.parse to
        versions.select! { |v| SemanticVersion.parse(v) <= to }
      end

      args = arguments.get("args").as_a

      if options.has? "fail-first"
        handle_fail_first versions, args.shift, args
      else
        handle_grouped versions, args.shift, args
      end
    ensure
      if initial
        ENV.switch ENV::LIBRARY_CRYSTAL / initial
      end
    end

    private def handle_grouped(versions : Array(String), command : String, args : Array(String)) : Nil
      p! command, args
      wg = WaitGroup.new(max = versions.size)
      result = Channel({String, String?}).new

      versions.each do |version|
        spawn do
          ENV.switch ENV::LIBRARY_CRYSTAL / version
          err = IO::Memory.new
          res = Process.run command, args, error: err

          if res.success?
            result.send({version, nil})
          else
            result.send({version, err.to_s})
          end

          wg.done
        end
      end

      spawn do
        while info = result.receive?
          puts info
        end

        wg.done
      end

      wg.wait
    end

    private def handle_fail_first(versions : Array(String), command : String, args : Array(String)) : Nil
      result = {} of String => Bool
      count = 1
      max = versions.size
      iter = versions.each

      STDERR << "\e[?25l"
      loop do
        version = iter.next
        break if version.is_a? Iterator::Stop

        ENV.switch ENV::LIBRARY_CRYSTAL / version
        STDERR << version << " (" << count << '/' << max << ")\r"

        proc = Process.run command, args
        result[version] = proc.success?
        break unless proc.success?
      end

      STDERR << "\e[F\e[?25h\e[2K"
      pp result
    end
  end
end
