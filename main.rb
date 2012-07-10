require 'rubygems'
require 'mtgox'
require 'date'
require 'ruby-debug'

require File.expand_path(File.join(File.dirname(__FILE__), "settings"))

puts
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
	trades = trades.select { |trade| trade.primary == "Y" }
	File.open(trades_filename,'w') do|file|
		file.puts trades.to_yaml
	end
else
	puts "loading trades from file"
	trades = YAML::load(File.read(trades_filename))
end

puts

last_trade = trades.reverse.first
previous_price = last_trade.price
trend = :flat
previous_trend = :flat
count = 0


trades.reverse.each do |trade| 
	#date = Time.at(trade.date).to_datetime

	if trade.price > previous_price then
		trend = :up
	end
	
	if trade.price < previous_price then
		trend = :down
	end
	
	if trend != previous_trend and previous_trend != :flat then
		break
	end;

	previous_trend = trend
	previous_price = trade.price	
	count += 1
end

puts "Last trend: #{trend.to_s.upcase}"
puts "for last #{count} transactions, started with #{previous_price}"
puts format "last transaction at #{last_trade.price}, difference to trend starter: %.5f", last_trade.price - previous_price

first_trade = trades.first
overall_trend = last_trade.price > first_trade.price ? :up : :down
overall_timespan = (last_trade.date - first_trade.date) / (60 * 60)

puts "Overall trend: #{overall_trend.to_s.upcase} over last #{overall_timespan.to_i} hours"
overall_difference = last_trade.price - first_trade.price
puts format "first transaction at #{first_trade.price}, last transaction at #{last_trade.price} , difference: %.5f", overall_difference

