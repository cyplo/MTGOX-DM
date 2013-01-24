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
if client.personal_trades.empty? then 
	puts "empty trades history, input a price below which you don't want to sell"
	limit = Float(gets)
else
	#todo
	limit = client.personal_trades.first.price
end

last_transaction_price = client.trades.sorted.first.price.to_f
puts "Last transaction priced at #{last_transaction_price}"

bought_at = limit

def get_new_selling_price trend, previous_price
	if trend == :up then 
		return previous_price + 0.01
	else 
		return previous_price - 0.01
	end
end

def get_new_buying_price selling_price
	selling_price - 0.01
end

selling_price = get_new_selling_price trend, last_transaction_price

if selling_price > bought_at then
	amount = 0.01
	puts "attempting to sell #{amount} BTC for at least #{selling_price}"
	buying_price = get_new_buying_price selling_price
	puts "making matching transaction to buy #{amount} BTC for at most #{buying_price}"
	gets		
end


#btc_amount = wallets.btc.balance.value
