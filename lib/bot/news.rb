module Bot
  class News
    def initialize(event)
      @event = event
      @channel = @event[:channel]
      @text = @event[:text].split[1..-1].join(' ')
      @uid = @event[:user]
    end

    def player_news
      stories = $redis.smembers "news:#{nation}"

      if !Util.news_open?
        msg 'The presses are currently stopped.'
      elsif stories.size == 0
        msg 'You have not submitted any stories.'
      else
        msg "_Here are your current stories as they will appear in the gazette_\n#{News.format(nation, stories)}"
      end
    end

    def self.publish!(channel)
      if !Util.news_open?
        Util.message channel, 'I cannot publish a gazette while the presses are stopped.'
        return
      end

      if $redis.keys('news:*').size == 0
        Util.message channel, 'I do not have any stories to publish.'
        return
      end

      output = ['_Here are the latest headlines from around Europe_']

      $redis.keys("news:*").each do |key|
        stories = $redis.smembers key
        country = key.match(/:(\w+)$/)[1]

        output << News.format(country, stories)

        $redis.del key
      end

      Util.message channel, output.join("\n")
    end

    def store!
      if Util.news_open?
        store_story
      else
        msg 'I am not currently accepting news stories'
      end
    end

    private

    def self.format(country, stories)
      output = []

      output += stories.map { |story| "*From #{country}:* \"#{story}\"" }

      output.join("\n")
    end

    def msg(text)
      Util.message(@channel, text)
    end

    def nation
      @nation ||= $redis.hget 'players', @uid
    end

    def store_story
      if $redis.sadd "news:#{nation}", @text
        msg "I have stored your \"#{@text}\" story"
      else
        msg "It looks like I already had \"#{@text}\" stored. You can say `mystories` to see your current news stories."
      end
    end
  end
end
