require 'rubygems'
require 'mtgox'
require File.expand_path(File.join(File.dirname(__FILE__), "settings"))

puts "Hello, this is cyplo's MtGox bot"
puts "Using #{@key} as key"
puts 

MtGox.configure do |configuration|
    configuration.currency = @currency
end

ticker = MtGox.ticker

puts "Last transaction was at " + ticker.last.to_s + " " + @currency.to_s

