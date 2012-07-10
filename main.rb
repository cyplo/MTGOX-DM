require 'rubygems'
require 'mtgox'
require File.expand_path(File.join(File.dirname(__FILE__), "settings"))

puts "Hello, this is cyplo's MtGox bot"
puts "using #{@key} as key"

MtGox.configure do |c|
    c.currency = :pln
end

p MtGox.ticker
