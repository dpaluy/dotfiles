if defined?(PryByebug)
  Pry.commands.alias_command 'con', 'continue'
  Pry.commands.alias_command 's', 'step'
  Pry.commands.alias_command 'n', 'next'
  Pry.commands.alias_command 'f', 'finish'
end

begin
  require 'awesome_print'

  module AwesomePrint
    Formatter.prepend(Module.new do
      def awesome_self(object, type)
        if type == :string && @options[:string_limit] && object.inspect.to_s.length > @options[:string_limit]
          colorize(object.inspect.to_s[0..@options[:string_limit]] + "...", type)
        else
          super(object, type)
        end
      end
    end)
  end

  AwesomePrint.defaults = {
    string_limit: 80,
    indent: 2,
    multiline: true
  }
  AwesomePrint.pry!
rescue
  puts 'There is no Awesome Print gem installed'
end

Pry.hooks.add_hook :after_read, :hack_utf8 do |str, _|
  str.force_encoding('utf-8')
end
