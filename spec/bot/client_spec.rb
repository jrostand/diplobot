require 'slack'
require_relative '../../lib/bot/client'

RSpec.describe 'Client' do
  describe '.init' do
    it 'calls Slack.configure' do
      expect(Slack).to receive :configure

      Bot::Client.new
    end

    it 'gets its bot token from Redis' do
      $redis = spy('redis')

      Bot::Client.new

      expect($redis).to have_received(:get).with('bot_token')
    end
  end
end
