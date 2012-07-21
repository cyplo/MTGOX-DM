require 'json'

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

def dehashify
end

def get url
	uri = URI(BASE_URI+url)
	response = nil
	Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
	  request = Net::HTTP::Get.new uri.request_uri
	  response = http.request request
	  response = response.body
	end
	response
end

end
