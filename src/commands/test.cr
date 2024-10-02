module Crimson::Commands
  class Test < Base
    def setup : Nil
      @name = "test"
      @summary = "test installed Crystal versions"
      @description = <<-DESC
        Tests a given command over a set of specified versions. By default this command
        will test all installed versions from the latest descending, but you can change
        this by specifying the '--order' flag which accepts asc(ending), desc(ending)
        and rand(om).

        If you only want to test a subset of versions then you can specify the '--from'
        flag with a version to start from and/or the '--to' flag with a version to stop
        at.

        The command will complete when all selected versions are tested, but this can be
        changed to stop at the first failure by specifying the '--fail-first' flag. The
        output from each version will be printed after all selected versions are tested
        unless the '--progress' flag is specified, in which case the output is printed
        after each version has been tested.
        DESC

      add_usage "test [-F|--fail-first] [-o|--order <asc|desc|random>] [--from <version>]" \
                "\n\t[--to <version>] [-p|--progress] <args...>"

      add_argument "args", description: "the command to test", multiple: true, required: true
      add_option 'F', "fail-first", description: "exit early at the first failed test"
      add_option 'o', "order", description: "the order to execute versions in", type: :single
      add_option "from", description: "the version to start testing from", type: :single
      add_option "to", description: "the version to stop testing at", type: :single
      add_option 'p', "progress", description: "print output after each test"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      super

      if order = options.get?("order").try &.as_s.downcase
        unless order.in?("asc", "ascending", "desc", "descending", "rand", "random")
          error "Invalid order value"
          fatal "See 'crimson test --help' for more information"
        end
      end
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      config = Config.load
      initial = config.current || config.default
      versions = ENV.installed_versions.reverse!
      exit_program if versions.empty?

      if from = options.get?("from").try &.as_s
        from = SemanticVersion.parse from
        versions.reject! { |v| v < from }
      end

      if to = options.get?("to").try &.as_s
        to = SemanticVersion.parse to
        versions.select! { |v| v <= to }
      end

      if order = options.get?("order").try &.as_s.downcase
        case order
        when "asc", "ascending"
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
        version = version.to_s
        ENV.switch ENV::LIBRARY_CRYSTAL / version
        STDERR << "Testing " << version << " (" << count << '/' << max << ")\r"

        proc = Process.run(command, args, error: err = IO::Memory.new)
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
      STDERR << "\e[?25h"
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
