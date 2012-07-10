require 'rubygems'
require 'mtgox'
require 'date'
require 'ruby-debug'

require File.expand_path(File.join(File.dirname(__FILE__), "settings"))


puts "Hello, this is cyplo's MtGox bot"
puts "Using #{@key} as key"
puts 

MtGox.configure do |configuration|
    configuration.currency = @currency
end

trades_filename = "trades.yaml"
fetch_delay = 60 #seconds

should_fetch=true
 if File.exists? trades_filename then
	last_fetched = File.mtime trades_filename
	difference = Time.now - last_fetched
	difference = difference.to_i
	should_fetch = difference > fetch_delay
end

trades = nil
if should_fetch then
	puts "fetching last trades from MtGox"
	trades = MtGox.trades :pln
	puts "saving trades in file"
	File.open(trades_filename,'w') do|file|
		file.puts trades.to_yaml
	end
else
	puts "loading trades from file"
	trades = YAML::load(File.read(trades_filename))
end

puts

last_trade = trades.reverse.first
current = last_trade.price
trend = :flat
previous_trend = :flat
count = 0


trades.reverse.each do |trade| 
	#date = Time.at(trade.date).to_datetime

	if trade.price > current then
		trend = :down
	end
	
	if trade.price < current then
		trend = :up
	end
	
	if trend != previous_trend and previous_trend != :flat then
		break
	end;

	previous_trend = trend
	
	current = trade.price
	count += 1
end

puts "Trend: #{previous_trend.to_s.upcase}"
puts "for last #{count} transactions, started with #{current}"
puts "last transaction at #{last_trade.price}, difference to trend starter: #{last_trade.price - current}"
