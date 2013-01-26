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

puts "MtGox fee: " + client.fee.to_s

def wait_for_funds client, money_needed
	sleep 15 until client.currency_balance >= money_needed
end

def buy amount, buying_price
	puts "[BUY]  #{amount} BTC for at most  #{buying_price} #{@currency}"
	begin
		MtGox.buy! amount, buying_price, @currency
	rescue => error
		puts "error buying, retrying"
		ap error
		sleep 15
		retry
	end
	wait_for_orders
end

def sell amount, price
	puts "[SELL] #{amount} BTC for at least #{price} #{@currency}"
	begin
		MtGox.sell! amount, price, @currency
	rescue => error
		puts "error selling, retrying"
		ap error
		sleep 15
		retry
	end
	wait_for_orders
end

def wait_for_orders
	begin
		sleep 30 until MtGox.buys.empty?
		sleep 30 until MtGox.sells.empty?
	rescue
		puts "error waiting, retrying"
		retry
	end
end

loop do
	puts "Last trend: #{client.trades.trend.to_s.upcase}, lasting for #{client.trades.trend_over} transactions"
	puts "you have #{client.btc_balance} BTC and #{client.currency_balance} #{@currency.to_s.upcase}"
	client.trades.write_graph
	last_transaction_price = client.trades.sorted.first.price.to_f
	puts "last transaction at #{last_transaction_price}"
	if client.currency_balance > 0 then
		buying_price = last_transaction_price
		if client.trades.trend == :up
			buying_price += 0.5
		else
			buying_price -= 0.2
		end
		amount = client.currency_balance / buying_price
		amount -= 0.001
		buy amount, buying_price
		selling_price = buying_price + 0.1
		sell client.btc_balance, selling_price
	else
		puts "waiting for funds..."
		wait_for_funds 1
	end
	sleep 15
end