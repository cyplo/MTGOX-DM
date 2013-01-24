require 'json'
require 'base64'
require 'hmac-sha1'
require 'awesome_print'
require File.expand_path(File.join(File.dirname(__FILE__), "cache"))
require File.expand_path(File.join(File.dirname(__FILE__), "trades"))

class MtGoxClient

BASE_URI = "https://mtgox.com/api/1/"

attr_reader :currency

def initialize currency=:pln, key=nil, secret=nil

@cache = PersistentCache.new
@currency = currency.to_s.upcase
@key=key
@secret=secret

MtGox.configure do |config|
  config.key = @key
  config.secret = @secret
end

@cache.init_with_fetcher :trades, lambda {
url = "BTC#{@currency}/trades?raw"
response = get url
trades = JSON.parse response
result = trades.map { |trade| DeHashable.new trade }
result = result.select { |trade| trade.primary.downcase=="y" }
Trades.new result
}

end

def trades
	@cache[:trades]
end

def balance
  MtGox.balance
end

def info
  MtGox.info
end

def fee
  info["Trade_Fee"]
end

private

class DeHashable
  def initialize(hash)
    hash.each do |k,v|
      self.instance_variable_set("@#{k}", v)  ## create and initialize an instance variable for this key/value pair
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## create the getter that returns the instance variable
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## create the setter that sets the instance variable
    end
  end
end



end
