require 'rubygems'
require 'mtgox'
require 'json'

require 'ruby-debug'

require File.expand_path(File.join(File.dirname(__FILE__), "settings"))
require File.expand_path(File.join(File.dirname(__FILE__), "cache"))
require File.expand_path(File.join(File.dirname(__FILE__), "trades"))

puts
puts "Hello, this is cyplo's MtGox bot"
puts "Using #{@key} as key"
puts 

MtGox.configure do |configuration|
    configuration.currency = @currency
    configuration.key = @key
    configuration.secret = @secret
end

cache = PersistentCache.new

cache.init_with_fetcher :trades, lambda {
trades = MtGox.trades @currency
trades = trades.select { |trade| trade.primary == "Y" }
}

cache.init_with_fetcher :info, lambda {
me = MtGox::Me.new
me.info
}

cache.init_with_fetcher :my_trades, lambda {
me = MtGox::Me.new
me.trades
}

cache.init_with_fetcher :market, lambda {
depth = MtGox.depth
}

trades = cache[:trades]
trades = Trades.new trades

puts "Last trend: #{trades.trend.to_s.upcase}, lasting for #{trades.trend_over} transactions"

fee = cache[:info]["Trade_Fee"]

puts "MtGox fee:" + fee.to_s

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
	puts "recommendation: sell BTC"
end

#btc_amount = wallets.btc.balance.value
