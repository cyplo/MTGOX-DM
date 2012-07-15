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

puts cache[:my_trades]

trades.write_graph

puts cache[:market].asks.first 10
puts cache[:market].bids.first 10

#btc_amount = wallets.btc.balance.value
