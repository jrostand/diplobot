module Bot
  class Client
    def initialize
      Slack.configure do |config|
        config.token = $redis.get 'bot_token'
      end

      $client ||= Slack::Web::Client.new
    end

    def im_list
      $client.im_list
    end

    def message(channel, text)
      $client.chat_postMessage({
        channel: channel,
        text: text
      })
    end

    def users_info
      $client.users_info
    end

    def users_list
      $client.users_list
    end
  end
end
