class Trades

attr_reader :trend
attr_reader :trend_over


def initialize trades
	@trades = trades
	#note the reverse order
	@trades.sort! { |a,b| b.date <=> a.date }
	recalculate_trend
end

private

def recalculate_trend
	first_trade = @trades.first
	previous_price = first_trade.price
	trend = :flat
	previous_trend = :flat
	count = 0
	@trades.each do |current_trade| #already sorted descending
	
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
