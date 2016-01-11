module BitcoinTicker
  module PriceComparer
    def compare_to_threshold(previous_price, current_price, threshold)
      (current_price - previous_price).abs > threshold
    end
    module_function :compare_to_threshold
  end
end
