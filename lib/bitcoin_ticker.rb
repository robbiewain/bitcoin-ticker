require "bitcoin_ticker/version"
require "bitcoin_ticker/price_checker"
require "bitcoin_ticker/price_comparer"
require "bitcoin_ticker/price_saver"
require "bitcoin_ticker/slack_notifier"

module BitcoinTicker
  class BitcoinTicker
    def tick
      current_price = PriceChecker.new.current_price
      price_saver = PriceSaver.new
      previous_price = price_saver.read
      if PriceComparer.new.compare_to_threshold previous_price, current_price, ENV["BITCOIN_PRICE_THRESHOLD"].to_f
        SlackNotifier.new.notify ENV["SLACK_WEBHOOK_URL"], current_price, current_price > previous_price
        price_saver.write current_price
      end
    end
  end
end
