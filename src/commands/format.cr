module Crimson::Commands
  def self.generate_template(command : Cling::Command) : String
    String.build do |io|
      if header = command.header
        io << header << "\n\n"
      else
        io << "Command ".colorize.red << command.name << "\n\n"
      end

      if description = command.description
        io << description << "\n\n"
      end

      unless command.usage.empty?
        io << "Usage".colorize.red << '\n'
        command.usage.each do |use|
          io << "• " << use << '\n'
        end
        io << '\n'
      end

      unless command.children.empty?
        io << "Commands".colorize.red << '\n'
        max_size = 4 + command.children.keys.max_of &.size

        command.children.each do |name, cmd|
          io << "• " << name
          if summary = cmd.summary
            io << " " * (max_size - name.size)
            io << summary
          end
          io << '\n'
        end
        io << '\n'
      end

      unless command.arguments.empty?
        io << "Arguments".colorize.red << '\n'
        command.arguments.each do |name, argument|
          io << "• " << name << '\t' << argument.description
          io << " (required)" if argument.required?
          io << '\n'
        end
        io << '\n'
      end

      io << "Options".colorize.red << '\n'
      max_size = 2 + command.options.max_of { |n, o| 2 + n.size + (o.short ? 2 : 0) }

      command.options.each do |name, option|
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
