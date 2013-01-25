require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'yaml'
#require 'ruby-debug'
require 'mtgox'


require_relative "settings"
require_relative "cmtgox"

puts
puts "Hello, this is cyplo's MtGox bot"
puts "Using #{@key} as key"
puts 


client = MtGoxClient.new @currency, @key, @secret

trend = client.trades.trend
puts "Last trend: #{trend.to_s.upcase}, lasting for #{client.trades.trend_over} transactions"
puts "you have #{client.btc_balance} BTC and #{client.currency_balance} #{@currency.to_s.upcase}"

puts "MtGox fee: " + client.fee.to_s

def get_new_selling_price trend, previous_price
	if trend == :up then 
		return previous_price - 0.00001
	else 
		return previous_price - 0.2
	end
end

def wait_for_funds client, money_needed
	sleep 15 until client.currency_balance >= money_needed
end

def buy amount, buying_price
	puts "[BUY]  #{amount} BTC for at most  #{buying_price} #{@currency}"
	begin
		MtGox.buy! amount, buying_price, @currency
	rescue
		puts "error buying, retrying"
		sleep 15
		retry
	end
	begin
		sleep 15
	end until MtGox.buys.empty?
end

def sell amount, price
	puts "[SELL] #{amount} BTC for at least #{price} #{@currency}"
	begin
		MtGox.sell! amount, price, @currency
	rescue
		puts "error selling, retrying"
		sleep 15
		retry
	end
	wait_for_orders
end

def wait_for_orders
	begin
		sleep 30 until MtGox.sells.empty?
	rescue
		puts "error waiting, retrying"
		retry
	end
end

loop do
	sleep 15
	client.trades.write_graph
	last_transaction_price = client.trades.sorted.first.price.to_f
	if client.currency_balance > 0 then
		buying_price = last_transaction_price
		if client.trades.trend == :up
			buying_price += 0.1
		else
			buying_price -= 0.1
		end
		amount = client.currency_balance / buying_price
		buy amount, buying_price
		selling_price = buying_price + 0.001
		sell client.btc_balance, selling_price
	else
		puts "waiting for funds..."
		wait_for_funds 1
	end
end