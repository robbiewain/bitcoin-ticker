module BitcoinTicker
  class PriceComparer
    def compare_to_threshold(previous_price, current_price, percent_change_threshold)
      ((current_price - previous_price).to_f / previous_price * 100).abs > percent_change_threshold
    end
  end
end
