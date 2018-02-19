require "bitcoin_ticker/version"
require "bitcoin_ticker/price_checker"
require "bitcoin_ticker/price_comparer"
require "bitcoin_ticker/price_saver"
require "bitcoin_ticker/slack_notifier"

module BitcoinTicker
  class BitcoinTicker
    def tick
      %i[btc bch eth ltc neo].each do |ticker|
        check_price(ticker)
      end
    end

    private

    def check_price(ticker)
      current_price = price_checker.current_price(ticker)
      previous_price = price_saver.read(ticker)
      if price_comparer.compare_to_threshold(previous_price, current_price, price_threshold)
        slack_notifier.notify(ticker, current_price, current_price > previous_price)
        price_saver.write(ticker, current_price)
      end
    end

    def price_threshold
      @price_threshold ||= ENV["PERCENT_CHANGE_THRESHOLD"].to_f
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
