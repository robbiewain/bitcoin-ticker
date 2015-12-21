# BitcoinTicker

A Bitcoin ticker that sends price changes to Slack

## Installation

Install Redis

## Configuration

The bitcoin ticker will only notify Slack if the bitcoin price changes by more than the threshold. To set the threshold to $10:
```
export BITCOIN_PRICE_THRESHOLD=10
```

A Slack webhook url is used to send the update to Slack. For example:
```
export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/123/123
```

## Run
```
bundle exec ruby bin/bitcoin-ticker
```
