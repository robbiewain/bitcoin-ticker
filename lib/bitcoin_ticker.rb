require "bitcoin_ticker/version"
require "bitcoin_ticker/price_checker"
require "bitcoin_ticker/price_comparer"
require "bitcoin_ticker/price_saver"
require "bitcoin_ticker/slack_notifier"

module BitcoinTicker
  class BitcoinTicker
    def tick
      check_price :btc
      check_price :eth
      check_price :ltc
      check_price :neo
    end

    private

    def check_price(ticker)
      current_price = price_checker.current_price ticker
      previous_price = price_saver.read ticker
      if price_comparer.compare_to_threshold previous_price, current_price, price_thresholds[ticker].to_f
        slack_notifier.notify ticker, current_price, current_price > previous_price
        price_saver.write ticker, current_price
      end
    end

    def price_thresholds
      @price_thresholds ||= {
        btc: ENV["BITCOIN_PRICE_THRESHOLD"],
        eth: ENV["ETHEREUM_PRICE_THRESHOLD"],
        ltc: ENV["LITECOIN_PRICE_THRESHOLD"],
        neo: ENV["NEO_PRICE_THRESHOLD"]
      }
    end

    def price_checker
      @price_checker ||= PriceChecker.new
    end

    def price_saver
      @price_saver ||= PriceSaver.new
    end

    def price_comparer
      @price_comparer ||= PriceComparer.new
    end

    def slack_notifier
      @slack_notifier ||= SlackNotifier.new
    end
  end
end
