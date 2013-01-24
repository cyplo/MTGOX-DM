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

puts client.balance
puts "MtGox fee:" + client.fee.to_s
gets



my_trades = cache[:my_trades]

trades.write_graph

btc_wallet = cache[:info]["Wallets"]["BTC"]
currency_wallet = cache[:info]["Wallets"][@currency.to_s.upcase]

btc_amount = btc_wallet["Balance"]["value"]
currency_amount = currency_wallet["Balance"]["value"]

puts "you have #{btc_amount} BTC and #{currency_amount} #{@currency.to_s.upcase}"


limit = 1
if my_trades.empty? then 
	puts "empty trades history, input a price below which you don't want to sell"
	limit = Float(gets)
end

last_transaction_price = trades.sorted.first.price
puts "Last transaction priced at #{last_transaction_price}"
if last_transaction_price > limit then
	if(trend == :up) then
		puts "attempting to sell BTC"
		gets
		me = MtGox::Me.new
		order = me.add "ask",btc_amount * 100000000, nil, @currency.to_s
		puts "done"
		gets
		puts order
	end
	
end

#btc_amount = wallets.btc.balance.value
