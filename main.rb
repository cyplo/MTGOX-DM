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
trades.reverse!
}

me = MtGox::Me.new
cache.init_with_fetcher :info, lambda {
me.info
}

cache.init_with_fetcher :my_trades, lambda {
me.trades
}

trades = cache[:trades]
trades = Trades.new trades

puts "Last trend: #{trades.trend.to_s.upcase}, lasting for #{trades.trend_over} transactions"
#puts "for last #{count} transactions, started with #{previous_price}"
#puts format "last transaction at #{last_trade.price}, difference to trend starter: %.5f", last_trade.price - previous_price

#first_trade = trades.first
#overall_trend = last_trade.price > first_trade.price ? :up : :down
#overall_timespan = (last_trade.date - first_trade.date) / (60 * 60)

#puts "Overall trend: #{overall_trend.to_s.upcase} over last #{overall_timespan.to_i} hours"
#overall_difference = last_trade.price - first_trade.price
#puts format "first transaction at #{first_trade.price}, last transaction at #{last_trade.price} , difference: %.5f", overall_difference

#me = MtGox::Me.new
fee = cache[:info]["Trade_Fee"]

puts "MtGox fee:" + fee.to_s

puts cache[:my_trades]

trades.write_graph

#btc_amount = wallets.btc.balance.value
#puts "BTC:"
#puts JSON.pretty_generate cache[:info]
