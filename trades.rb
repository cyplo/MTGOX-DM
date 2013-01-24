
require 'rubygems'
require 'SVG/Graph/Line'


class Trades

attr_reader :trend
attr_reader :trend_over
attr_reader :sorted

def initialize trades
	@trades = trades
	#note the reverse order
	@sorted = @trades.sort { |a,b| b.date <=> a.date }
	recalculate_trend
end

def write_graph count=8

dates =  Array.new
values = Array.new

trades = @trades.last count

trades.each { |trade|
	date = Time.at trade.date
	dates << date.strftime('%d %B %k:%m')
	values << trade.price.to_f
}

fields = dates

graph = SVG::Graph::Line.new({
	:height => 512,
 	:width => 1200,
	:fields => fields
})

graph.add_data({
	:data => values
})

graph = graph.burn
File.open("trades.svg",'w') do|file|
	file.puts graph
end

end

private

def recalculate_trend
	first_trade = @sorted.first
	previous_price = first_trade.price
	trend = :flat
	previous_trend = :flat
	count = 0
	@sorted.each do |current_trade|
	
	previous_trend = trend
	if previous_price > current_trade.price then
		#puts "deciding UP, #{previous_price} vs #{current_trade.price}"
		trend = :up
	end
	
	if previous_price < current_trade.price  then
		#puts "deciding DOWN, #{previous_price} vs #{current_trade.price}"	
		trend = :down
	end
	
	if trend != previous_trend and previous_trend != :flat then
		break
	end;

	previous_price = current_trade.price	
	count += 1
	end
	
	@trend = previous_trend
	@trend_over = count
end

end
