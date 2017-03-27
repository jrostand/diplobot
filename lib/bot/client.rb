module Bot
  class Client
    def self.init
      Slack.configure do |config|
        config.token = $redis.get 'bot_token'
      end

      Slack::Web::Client.new
    end
  end
end
