require "spec_helper"
require "bitcoin_ticker.rb"

module BitcoinTicker
  describe BitcoinTicker do
    let(:ticker) { BitcoinTicker.new }
    let(:slack_webhook_url) { "https://hooks.slack.com/services/123/123" }
    let(:slack_notifier) { double "Slack Notifier" }
    let(:price_saver) { double "Price Saver", read: previous_price, write: true }
    before do
      expect(ENV).to receive(:[]).with("BITCOIN_PRICE_THRESHOLD").and_return "10"
      allow(ENV).to receive(:[]).with("SLACK_WEBHOOK_URL").and_return slack_webhook_url
      expect(PriceChecker).to receive_message_chain(:new, :current_price).and_return current_price
      expect(PriceSaver).to receive(:new) { price_saver }
      allow(SlackNotifier).to receive(:new).and_return slack_notifier
    end
    context "price rise" do
      let(:current_price) { 100 }
      let(:previous_price) { 50 }
      it "notifies slack when price and saves new price" do
        expect(slack_notifier).to receive(:notify).with slack_webhook_url, 100, true
        expect(price_saver).to receive(:write).with 100
        ticker.tick
      end
      context "less than threshold" do
        let(:current_price) { 45 }
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
        expect(slack_notifier).to receive(:notify).with slack_webhook_url, 50, false
        expect(price_saver).to receive(:write).with 50
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
        .with(URI(PriceChecker::COINBASE_SPOT_PRICE_URI))
        .and_return(OpenStruct.new status: 200, body: "{ \"data\": { \"amount\": \"#{price}\" } }")
    end
    it "returns the price" do
      expect(price_checker.current_price).to eq price
    end
  end

  describe PriceSaver do
    let(:price_saver) { described_class.new }
    before { Redis.new.del PriceSaver::REDIS_KEY }
    it "starts empty" do
      expect(price_saver.read).to eq 0.0
    end
    it "saves the price" do
      price = 500.13
      price_saver.write price
      expect(price_saver.read).to eq price
    end
  end

  describe PriceComparer do
    let(:price_comparer) { described_class.new }
    it "returns true if increased more than threshold" do
      expect(price_comparer.compare_to_threshold 10, 20, 5).to be true
    end
    it "returns false if lower than threshold" do
      expect(price_comparer.compare_to_threshold 10, 20, 50).to be false
    end
    it "returns false if equal to threshold" do
      expect(price_comparer.compare_to_threshold 10, 20, 10).to be false
    end
    it "returns true if descreased more than threshold" do
      expect(price_comparer.compare_to_threshold 20, 10, 5).to be true
    end
  end

  describe SlackNotifier do
    let(:slack_notifier) { described_class.new }
    let(:current_price) { 123.45 }
    let(:webhook_url) { "https://slack.com/webhook_url/123" }
    let(:text) { "Bitcoin is up to $#{current_price}" }
    let(:username) { "bitcoin-ticker" }
    let(:icon_url) { "https://en.bitcoin.it/w/images/en/2/29/BC_Logo_.png" }
    let(:payload) { "{\"text\":\"#{text}\",\"username\":\"#{username}\",\"icon_url\":\"#{icon_url}\"}" }
    before { expect(Net::HTTP).to receive(:post_form).with URI(webhook_url), payload: payload }
    it "posts current price to slack" do
      slack_notifier.notify webhook_url, current_price, true
    end
    context "price drop" do
      let(:text) { "Bitcoin is down to $#{current_price}" }
      it "posts current price to slack" do
        slack_notifier.notify webhook_url, current_price, false
      end
    end
  end
end
