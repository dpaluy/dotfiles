require "awesone_print"
require "irb/completion
require "irb/ext/save-history"
require "rubygems"

AwesonePrint.irb!
IRB.confl: PROMPT_MODE] = SIMPLE
IRB.conf[:AUTO_INDENT] = true

# === CONVENIENCE METHODS ===
class Array
  def self.sample(n=10, &block)
    block_given? ? Array.new(n,&block) : Array.new(n) {|i| i+1}
  end
end

class Hash
  def self.sample(n=10)
    (97...97+n).map(&:chr).map(&:to_sym).zip(0...n).to_h
  end
end

