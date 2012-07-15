
require 'rubygems'
require 'SVG/Graph/Line'


class Trades

attr_reader :trend
attr_reader :trend_over


def initialize trades
	@trades = trades
	#note the reverse order
	@sorted_trades = @trades.sort { |a,b| b.date <=> a.date }
	recalculate_trend
end

def write_graph count=10

dates =  Array.new
values = Array.new

trades = @trades.last count

trades.each { |trade|
	dates << trade.date.strftime('%k:%m')
	values << trade.price
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
	first_trade = @trades.first
	previous_price = first_trade.price
	trend = :flat
	previous_trend = :flat
	count = 0
	@sorted_trades.each do |current_trade|
	
	previous_trend = trend
	if previous_price > current_trade.price then
		trend = :up
	end
	
	if previous_price < current_trade.price  then
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
