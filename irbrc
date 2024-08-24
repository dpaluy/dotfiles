#!/usr/bin/ruby

# frozen.string literal: true

require "irb/completion"
# require "irb/ext/save-history"
require "rubygems"

begin
  require "amazing_print"
  AmazingPrint.pry!
rescue
  puts 'gem install amazing_print  # <-- highly recommended'
end

IRB.conf[:PROMPT_MODE] = :SIMPLE
IRB.conf[:AUTO_INDENT] = true

# === CONVENIENCE METHODS ===
class Array
  def self.sample(n = 10, &block)
    block_given? ? Array.new(n, &block) : Array.new(n) { |i| i + 1 }
  end
end

class Hash
  def self.sample(n = 10)
    (97...97+n).map(&:chr).map(&:to_sym).zip(0...n).to_h
  end
end

class String
  def red
    "\e[31m#{self}\e[0m"
  end
  def cyan
    "\e[36m#{self}\e[0m"
  end
end

if defined?(Rails)
  module Rails::ConsoleMethods
    alias r reload!

    def cuser
      User.first
    end
  end

  project_name = File.basename(Dir.pwd).cyan
  environment = ENV['RAILS_ENV'][0..2].red
  prompt = "#{project_name}[#{environment}]"

  IRB.conf[:PROMPT] ||= {}
  IRB.conf[:PROMPT][:RAILS] = {
    PROMPT_I: "#{prompt} %03n > ",
    PROMPT_S: "#{prompt} %03n * ",
    PROMPT_C: "#{prompt} %03n ? ",
    RETURN: "=> %s\n"
  }

  IRB.conf[:PROMPT_MODE] = :RAILS
end
