module Crimson::Commands
  class Bisect < Base
    def setup : Nil
      @name = "bisect"

      add_alias "bi"
      add_usage "bisect [-F|--fail-first] [--from <version>] [-o|--order <asc|desc|random>] [--to <version>] <args>"

      add_argument "args", multiple: true, required: true
      add_option 'F', "fail-first"
      add_option 'o', "order", type: :single
      add_option "from", type: :single
      add_option "to", type: :single
      add_option 'p', "progress"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      super

      if order = options.get?("order").try &.as_s.downcase
        unless order.in?("asc", "ascending", "desc", "descending", "rand", "random")
          error "Invalid order value"
          fatal "See 'crimson bisect --help' for more information"
        end
      end
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load
      initial = config.current || config.default
      versions = ENV.get_installed_versions.sort_by { |v| SemanticVersion.parse(v) }
      exit_program if versions.empty?

      if from = options.get?("from").try &.as_s
        from = SemanticVersion.parse from
        versions.reject! { |v| SemanticVersion.parse(v) < from }
      end

      if to = options.get?("to").try &.as_s
        to = SemanticVersion.parse to
        versions.select! { |v| SemanticVersion.parse(v) <= to }
      end

      if order = options.get?("order").try &.as_s.downcase
        case order
        when "desc", "descending"
          versions.reverse!
        when "rand", "random"
          versions.shuffle!
        end
      end

      args = arguments.get("args").as_a
      fail_first = options.has? "fail-first"
      progress = options.has? "progress"
      command = args.shift
      results = {} of String => String?
      count = 1
      max = versions.size

      STDERR << "\e[?25l"
      versions.each do |version|
        ENV.switch ENV::LIBRARY_CRYSTAL / version
        STDERR << "Testing " << version << " (" << count << '/' << max << ")\r"

        proc = Process.run(command, args, error: err = IO::Memory.new)
        results[version] = proc.success? ? nil : err.to_s
        STDERR << "\e[2K\r"

        if fail_first && !proc.success?
          print version, err.to_s
          return
        end

        if progress
          print(version, proc.success? ? nil : err.to_s)
        else
          results[version] = proc.success? ? nil : err.to_s
        end

        count += 1
      end

      unless progress
        results.each do |(version, result)|
          print version, result
        end
      end
    ensure
      if initial
        ENV.switch ENV::LIBRARY_CRYSTAL / initial
      end
    end

    private def print(version : String, result : String?) : Nil
      STDOUT << version << " • "
      if result
        STDOUT << "Failed\n".colorize.red
        result.each_line do |line|
          STDOUT << "┃ ".colorize.dark_gray << line << '\n'
        end
        STDOUT << '\n'
      else
        STDOUT << "Passed\n".colorize.green
      end
    end
  end
end
