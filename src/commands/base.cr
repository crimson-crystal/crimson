module Crimson::Commands
  abstract class Base < Cling::Command
    def initialize
      super

      @verbose = false
      @inherit_options = true
      add_option 'h', "help", description: "get help information"
      add_option "no-color", description: "disable ansi color formatting"
      add_option 'v', "verbose", description: "display verbose logging"
    end

    def help_template : String
      Commands.generate_template self
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
      Colorize.enabled = false if options.has? "no-color"
      @verbose = true if options.has? "verbose"

      if options.has? "help"
        puts help_template

        false
      else
        true
      end
    end

    def on_error(ex : Exception) : Nil
      case ex
      when Cling::CommandError
        on_invalid_option ex.to_s
      when Cling::ExecutionError
        error ex.to_s
        command = "crimson #{self.name} --help".colorize.bold
        error "See '#{command}' for more information"
      when SystemExit
        # skip
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

      exit 1
    end

    def on_missing_arguments(args : Array(String))
      error "Missing required argument#{"s" if args.size > 1}: #{args.join(", ")}"
      command = "crimson #{self.name} --help".colorize.bold
      error "See '#{command}' for more information"
      exit 1
    end

    def on_unknown_arguments(args : Array(String))
      error "Unexpected argument#{"s" if args.size > 1}: #{args.join(", ")}"
      command = "crimson #{self.name} --help".colorize.bold
      error "See '#{command}' for more information"
      exit 1
    end

    def on_invalid_option(message : String)
      error message
      command = self.name == "app" ? "crimson --help" : "crimson #{self.name} --help"
      error "See '#{command.colorize.bold}' for more information"
    end

    def on_unknown_options(options : Array(String))
      error "Unexpected option#{"s" if options.size > 1}: #{options.join(", ")}"
      command = "crimson #{self.name} --help".colorize.bold
      error "See '#{command}' for more information"
      exit 1
    end

    def system_exit : NoReturn
      raise SystemExit.new
    end

    protected def verbose(& : ->) : Nil
      return unless @verbose
      STDOUT << yield << '\n'
    end
  end
end

def warn(data : _) : Nil
  STDOUT << "warn".colorize.yellow << ": " << data << '\n'
end

def error(data : _) : Nil
  STDERR << "error".colorize.red << ": " << data << '\n'
end

def should_continue? : Bool
  loop do
    print "\nDo you want to continue? (y/n) "
    case gets.try &.chomp
    when "y", "ye", "yes"
      return true
    when "n", "no"
      return false
    else
      error "Invalid prompt answer (must be yes or no)"
    end
  end
end
