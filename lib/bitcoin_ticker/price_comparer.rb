module BitcoinTicker
  class PriceComparer
    def compare_to_threshold(previous_price, current_price, threshold)
      (current_price - previous_price).abs > threshold
    end
  end
end
