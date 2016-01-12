require "bitcoin_ticker/version"
require "bitcoin_ticker/price_checker"
require "bitcoin_ticker/price_comparer"
require "bitcoin_ticker/price_saver"
require "bitcoin_ticker/slack_notifier"

module BitcoinTicker
  class BitcoinTicker
    include PriceComparer
    DEFAULT_PRICE_THRESHOLD = 10.0

    # call-seq:
    #   BitcoinTicker.new price_threshold, slack_webhook_url
    #
    # Parameters:
    #   * price_threshold   [Float] : Minimum variation of the BTC price before considering communicating it (default: 10.0)
    #   * slack_webhook_url [String]: URL of the Slack Webhook
    def initialize(price_threshold: DEFAULT_PRICE_THRESHOLD, slack_webhook_url:)
      self.price_threshold   = price_threshold
      self.notifier          = SlackNotifier.new(webhook_url: slack_webhook_url)
      self.price_saver       = PriceSaver.new
      self.price_checker     = PriceChecker.new
    end

    def tick
      current_price = price_checker.current_price
      previous_price = price_saver.read

      if compare_to_threshold previous_price, current_price, price_threshold
        notifier.notify current_price, current_price > previous_price
        price_saver.write current_price
      end
    end

    private
    attr_accessor :price_threshold, :notifier, :price_saver, :price_checker
  end
end
