require "cling"
require "colorize"
require "crest"
require "file_utils"
require "ini"
require "semantic_version"

require "./commands/base"
require "./commands/*"
require "./config"
require "./env"

module Crimson
  VERSION = "1.0.0"

  BUILD_DATE = {% if flag?(:win32) %}
                 {{ `powershell.exe -NoProfile Get-Date -Format "yyyy-MM-dd"`.stringify.chomp }}
               {% else %}
                 {{ `date +%F`.stringify.chomp }}
               {% end %}

  BUILD_HASH = {{ env("CRIMSON_HASH") || `git rev-parse HEAD`.stringify[0...8] }}

  class App < Commands::Base
    def setup : Nil
      @name = "app"
      @header = %(#{"Crimson".colorize.red} • #{"A Crystal Version Manager".colorize.light_red})

      add_command Commands::Setup.new
      add_command Commands::Env.new
      add_command Commands::Install.new
      add_command Commands::Import.new
      add_command Commands::Remove.new
      add_command Commands::List.new
      add_command Commands::Alias.new
      add_command Commands::Default.new
      add_command Commands::Switch.new
      add_command Commands::Test.new
      add_command Commands::Help.new
      add_command Commands::Version.new
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      puts help_template
    end
  end
end
