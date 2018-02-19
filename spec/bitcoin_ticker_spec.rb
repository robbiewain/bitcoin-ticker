require "spec_helper"
require "bitcoin_ticker.rb"

module BitcoinTicker
  describe BitcoinTicker do
    let(:ticker) { BitcoinTicker.new }
    let(:slack_webhook_url) { "https://hooks.slack.com/services/123/123" }
    let(:slack_notifier) { instance_double("Slack Notifier") }
    let(:price_saver) { instance_double("Price Saver") }
    let(:price_checker) { instance_double("Price Checker") }
    before do
      allow(ENV).to receive(:[]).with("PERCENT_CHANGE_THRESHOLD").and_return("10")
      allow(ENV).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return(slack_webhook_url)
      allow(ticker).to receive(:price_checker) { price_checker }
      allow(price_checker).to receive(:current_price) { current_price }
      allow(ticker).to receive(:price_saver) { price_saver }
      allow(price_saver).to receive(:read) { previous_price }
      allow(ticker).to receive(:slack_notifier).and_return(slack_notifier)
    end
    context "price rise" do
      let(:current_price) { 100 }
      let(:previous_price) { 50 }
      it "notifies slack when price and saves new price" do
        BitcoinTicker::TICKERS.each do |ticker|
          expect(slack_notifier).to receive(:notify).with(ticker, 100, true)
          expect(price_saver).to receive(:write).with(ticker, 100)
        end
        ticker.tick
      end
      context "less than threshold" do
        let(:current_price) { 49 }
        it "doesn't notify slack or save the new price" do
          expect(slack_notifier).not_to receive(:notify)
          expect(price_saver).not_to receive(:write)
          ticker.tick
        end
      end
    end
    context "price drop" do
      let(:current_price) { 50 }
      let(:previous_price) { 100 }
      it "notifies slack when price and saves new price" do
        BitcoinTicker::TICKERS.each do |ticker|
          expect(slack_notifier).to receive(:notify).with(ticker, 50, false)
          expect(price_saver).to receive(:write).with(ticker, 50)
        end
        ticker.tick
      end
      context "less than threshold" do
        let(:current_price) { 95 }
        it "doesn't notify slack or save the new price" do
          expect(slack_notifier).not_to receive(:notify)
          expect(price_saver).not_to receive(:write)
          ticker.tick
        end
      end
    end
  end

  describe PriceChecker do
    let(:price_checker) { described_class.new }
    let(:price) { 1000 }
    before do
      expect(Net::HTTP).to receive(:get_response)
        .with(URI(PriceChecker::PRICE_URIS[:btc]))
        .and_return(OpenStruct.new status: 200, body: "{ \"data\": { \"amount\": \"#{price}\" } }")
      expect(Net::HTTP).to receive(:get_response)
        .with(URI(PriceChecker::PRICE_URIS[:neo]))
        .and_return(OpenStruct.new status: 200, body: "[ { \"price_usd\": \"#{price}\" } ]")
    end
    it "returns the price" do
      expect(price_checker.current_price(:btc)).to eq price
      expect(price_checker.current_price(:neo)).to eq price
    end
  end

  describe PriceSaver do
    let(:price_saver) { described_class.new }
    before do
      Redis.new.del("btc-price")
    end
    it "starts empty" do
      expect(price_saver.read(:btc)).to eq(0.0)
    end
    it "saves the price" do
      price = 500.13
      price_saver.write(:btc, price)
      expect(price_saver.read(:btc)).to eq(price)
    end
  end

  describe PriceComparer do
    let(:price_comparer) { described_class.new }
    it "returns true if increased more than threshold" do
      expect(price_comparer.compare_to_threshold(10, 20, 5)).to be true
    end
    it "returns false if lower than threshold" do
      expect(price_comparer.compare_to_threshold(10, 14, 50)).to be false
    end
    it "returns false if equal to threshold" do
      expect(price_comparer.compare_to_threshold(10, 11, 10)).to be false
    end
    it "returns true if descreased more than threshold" do
      expect(price_comparer.compare_to_threshold(20, 10, 5)).to be true
    end
  end

  describe SlackNotifier do
    let(:slack_notifier) { described_class.new }
    let(:current_price) { 123.45 }
    let(:webhook_url) { "https://slack.com/webhook_url/123" }
    before do
      allow(ENV).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return webhook_url
    end
    it "has a full name and username for each supported ticker" do
      BitcoinTicker::TICKERS.each do |ticker|
        expect(SlackNotifier::FULLNAMES).to have_key(ticker)
        expect(SlackNotifier::USERNAMES).to have_key(ticker)
      end
    end
    it "posts current price to slack" do
      payload = '{"text":"Bitcoin is up to $123.45","username":"bitcoin-ticker"}'
      expect(Net::HTTP).to receive(:post_form).with(URI(webhook_url), payload: payload)
      slack_notifier.notify(:btc, current_price, true)
    end
    context "price drop" do
      it "posts current price to slack" do
        payload = '{"text":"Ethereum is down to $123.45","username":"ethereum-ticker"}'
        expect(Net::HTTP).to receive(:post_form).with(URI(webhook_url), payload: payload)
        slack_notifier.notify(:eth, current_price, false)
      end
    end
  end
end
