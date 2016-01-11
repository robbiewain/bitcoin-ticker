require "bitcoin_ticker/version"
require "bitcoin_ticker/price_checker"
require "bitcoin_ticker/price_comparer"
require "bitcoin_ticker/price_saver"
require "bitcoin_ticker/slack_notifier"

module BitcoinTicker
  class BitcoinTicker
    # call-seq:
    #   BitcoinTicker.new price_threshold, slack_webhook_url
    #
    # Parameters:
    #   * price_threshold   [Float] : Minimum variation of the BTC price before considering communicating it
    #   * slack_webhook_url [String]: URL of the Slack Webhook
    def initialize(price_threshold: ENV["BITCOIN_PRICE_THRESHOLD"].to_f, slack_webhook_url: ENV["SLACK_WEBHOOK_URL"])
      self.price_threshold = price_threshold
      self.slack_webhook_url = slack_webhook_url
      self.notifier = SlackNotifier.new(slack_webhook_url)
    end

    def tick
      current_price = PriceChecker.new.current_price
      price_saver = PriceSaver.new
      previous_price = price_saver.read
      if PriceComparer.compare_to_threshold previous_price, current_price, price_threshold
        notifier.notify slack_webhook_url, current_price, current_price > previous_price
        price_saver.write current_price
      end
    end

    private
    attr_accessor :price_threshold, :notifier
  end
end
