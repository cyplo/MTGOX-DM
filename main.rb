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

trades = MtGox.trades :pln
puts "Got #{trades.count} last pln trades"

puts "Finding the trend..."
current = trades.reverse.first.price
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

puts "Trend: #{previous_trend}, for last #{count} transactions"

