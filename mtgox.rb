require 'json'
require 'base64'
require 'hmac-sha1'

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

@cache.init_with_fetcher :info, lambda {
url = "generic/private/info"
response = post url
}
end

def trades
	@cache[:trades]
end

def info
	@cache[:info]
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


def sign_request method, request, data=nil
	if method == :post then
		puts @secret
		data_text = post_data_to_text data
		signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest 'sha512',
        Base64.decode64(@secret),
        data_text
		)
		puts signature
		gets
		request["Rest-Sign"] = signature
	end
end

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
		end
		request["User-Agent"] = "cyplo.net"
        request["Rest-Key"] = @key
        sign_request method, request, data
        puts request.inspect
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
