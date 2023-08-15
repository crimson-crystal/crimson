module Crimson::Commands
  abstract class Base < Cling::Command
    def initialize
      super

      @verbose = false
      @inherit_options = true
      add_option "no-color", description: "disable ansi color formatting"
      add_option 'h', "help", description: "get help information"
    end

    def help_template : String
      Commands.generate_template self
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
      Colorize.enabled = false if options.has? "no-color"
      @verbose = true if options.has? "verbose"

      if options.has? "help"
        stdout.puts help_template

        false
      else
        true
      end
    end

    def on_error(ex : Exception) : Nil
      case ex
      when Cling::CommandError
        error ex.to_s
        error "See 'crimson --help' for more information"
      when Cling::ExecutionError
        error ex.to_s
        error "See 'crimson #{self.name} --help' for more information"
      else
        error "Unexpected exception:"
        error ex.to_s
        error "Please report this on the Crimson GitHub issues:"
        error "https://github.com/devnote-dev/crimson/issues"

        if @verbose
          trace = ex.backtrace || %w[???]
          trace.each { |line| error line }
        end
      end
    end

    def on_missing_arguments(args : Array(String))
      error "Missing required argument#{"s" if args.size > 1}: #{args.join(", ")}"
      error "See 'crimson #{self.name} --help' for more information"
    end

    def on_unknown_arguments(args : Array(String))
      error "Unexpected argument#{"s" if args.size > 1}: #{args.join(", ")}"
      error "See 'crimson #{self.name} --help' for more information"
    end

    def on_unknown_options(options : Array(String))
      error "Unexpected option#{"s" if options.size > 1}: #{options.join(", ")}"
      error "See 'crimson #{self.name} --help' for more information"
    end

    protected def verbose(& : -> String) : Nil
      return unless @verbose
      stdout << yield << '\n'
    end

    protected def info(data : String) : Nil
      stdout << data << '\n'
    end

    protected def notice(data : String) : Nil
      stdout << "notice".colorize.cyan << ": " << data << '\n'
    end

    protected def warn(data : String) : Nil
      stdout << "warn".colorize.yellow << ": " << data << '\n'
    end

    protected def error(data : String) : Nil
      stderr << "error".colorize.red << ": " << data << '\n'
    end
  end
end
