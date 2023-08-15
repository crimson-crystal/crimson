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
      String.build do |io|
        if header
          io << header << "\n\n"
        else
          io << "Command ".colorize.red << name << "\n\n"
        end

        if description
          io << description << "\n\n"
        end

        unless usage.empty?
          io << "Usage".colorize.red << '\n'
          usage.each do |use|
            io << "• " << use << '\n'
          end
          io << '\n'
        end

        unless children.empty?
          io << "Commands".colorize.red << '\n'
          max_size = 4 + children.keys.max_of &.size

          children.each do |name, cmd|
            io << "• " << name
            if summary = cmd.summary
              io << " " * (max_size - name.size)
              io << summary
            end
            io << '\n'
          end
          io << '\n'
        end

        unless arguments.empty?
          io << "Arguments".colorize.red << '\n'
          arguments.each do |name, argument|
            io << "• " << name << '\t' << argument.description
            io << " (required)" if argument.required?
            io << '\n'
          end
          io << '\n'
        end

        io << "Options".colorize.red << '\n'
        max_size = 2 + options.max_of { |n, o| 2 + n.size + (o.short ? 2 : 0) }

        options.each do |name, option|
          name_size = 2 + option.long.size + (option.short ? 2 : -2)

          io << "• "
          if short = option.short
            io << '-' << short << ", "
          end
          io << "--" << name
          io << " " * (max_size - name_size)
          io << option.description << '\n'
        end
      end
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
        error [ex.to_s, "See 'crimson --help' for more information"]
      when Cling::ExecutionError
        error [ex.to_s, "See 'crimson #{self.name} --help' for more information"]
      else
        error [
          "Unexpected exception:",
          ex.to_s,
          "Please report this on the Crimson GitHub issues:",
          "https://github.com/devnote-dev/crimson/issues",
        ]
      end
    end

    def on_missing_arguments(args : Array(String))
      error [
        "Missing required argument#{"s" if args.size > 1}: #{args.join(", ")}",
        "See 'crimson #{self.name} --help' for more information",
      ]
    end

    def on_unknown_arguments(args : Array(String))
      error [
        "Unexpected argument#{"s" if args.size > 1}: #{args.join(", ")}",
        "See 'crimson #{self.name} --help' for more information",
      ]
    end

    def on_unknown_options(options : Array(String))
      error [
        "Unexpected option#{"s" if options.size > 1}: #{options.join(", ")}",
        "See 'crimson #{self.name} --help' for more information",
      ]
    end

    protected def verbose(& : -> String) : Nil
      return unless @verbose
      stdout << yield << '\n'
    end

    protected def info(data : String) : Nil
      stdout << "(i) ".colorize.blue << data << '\n'
    end

    protected def warn(data : String) : Nil
      stdout << "(!) ".colorize.yellow << data << '\n'
    end

    protected def warn(data : Array(String)) : Nil
      data.each &->warn(String)
    end

    protected def error(data : String) : Nil
      stderr << "(!) ".colorize.red << data << '\n'
    end

    protected def error(data : Array(String)) : Nil
      data.each &->error(String)
    end
  end
end
