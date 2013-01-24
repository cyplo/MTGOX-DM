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

client.trades.write_graph


limit = 1
last_transaction_price = client.trades.sorted.first.price.to_f
puts "Last transaction priced at #{last_transaction_price}"
if client.personal_trades.empty? then 
	puts "empty trades history, input a price below which you don't want to sell"
	limit = Float(gets)
else
	#todo
	limit = client.personal_trades.first.price
end



bought_at = limit

def get_new_selling_price trend, previous_price
	if trend == :up then 
		return previous_price - 0.00001
	else 
		return previous_price - 0.2
	end
end

def get_new_buying_price selling_price
	selling_price - 0.0001
end

def wait_for_funds client, money_needed
	sleep 15 until client.currency_balance >= money_needed
end

selling_price = get_new_selling_price trend, last_transaction_price
while selling_price > bought_at and client.btc_balance > 1.0
	sleep 1
	#refresh
	last_transaction_price = client.trades.sorted.first.price.to_f
	money_having = client.currency_balance
	trend = client.trades.trend
	sleep 1

	amount = 0.01
	selling_price = get_new_selling_price trend, last_transaction_price
	puts "[SELL] #{amount} BTC for at least #{selling_price} #{@currency}"
	#todo: check for last sell transactions to match
	begin
		MtGox.sell! amount, selling_price, @currency
	rescue
		puts "error selling, continuing"
	end
	begin
		sleep 30 until MtGox.sells.empty?
	rescue
		puts "error waiting, retrying"
		retry
	end
	buying_price = get_new_buying_price selling_price
	money_needed = amount * buying_price
	if(money_having == 0) then 
		puts "oops, don't have #{money_needed} #{@currency} to continue, waiting for selling orders to flush"
		wait_for_funds client, money_needed
		puts "money's back !"
	end
	if(money_having < money_needed) then
		amount = money_having / buying_price
	end
	puts "[BUY]  #{amount} BTC for at most  #{buying_price} #{@currency}"
	begin
		MtGox.buy! amount, buying_price, @currency
		bought_at = buying_price
	rescue
		puts "error buying, continuing"
	end
	begin
		sleep 30 until MtGox.sells.empty?
		sleep 30 until MtGox.buys.empty?
	rescue
		puts "error waiting, retrying"
		retry
	end
end


#btc_amount = wallets.btc.balance.value
