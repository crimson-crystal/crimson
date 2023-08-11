module Crimson::Commands
  abstract class Base < Cling::Command
    def initialize
      super

      @inherit_options = true
      add_option "no-color", description: "disable ansi color formatting"
      add_option 'h', "help", description: "get help information"
    end

    def help_template : String
      String.build do |io|
        if header
          io << header << "\n\n"
        else
          io << "Crimson: " << name << '\n'
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
  end
end
