require 'json'
require 'ostruct'
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
  result = trades.map { |trade| OpenStruct.new trade }
  result = result.select { |trade| trade.primary.downcase=="y" }
  Trades.new result
}

@cache.init_with_fetcher :info, lambda {
  MtGox.info
}
end

def trades
	@cache[:trades]
end

def btc_balance
  info["Wallets"]["BTC"]["Balance"]["value"]
end

def currency_balance
  info["Wallets"][@currency]["Balance"]["value"]
end

def info
  @cache[:info]
end

def fee
  info["Trade_Fee"]
end

private


def post_data_to_text data
	data_array = data.map { |k,v| "#{k}=#{v}" }
	data_text = data_array.join '&'
end

def request url, method=:get
	uri = URI(BASE_URI+url)
	response = nil
	Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
		request = Net::HTTP::Get.new uri.request_uri
		data=nil
		if method==:post then
			request = Net::HTTP::Post.new uri.request_uri
			data = Hash.new
			data['nonce']=Time.now.to_i
			request.body = (post_data_to_text data)
			ap request.body
			request["Rest-Key"] = @key
		end
    response = http.request request
		response = response.body
	end
	response
end

def get url
	request url
end

def post url
	request url, :post
end


end
