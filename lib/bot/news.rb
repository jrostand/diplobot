module Bot
  class News < BaseModule
    class << self
      def count_for(nation)
        $redis.scard("news:#{nation}")
      end

      def for(nation)
        $redis.smembers("news:#{nation}").join(', ')
      end
    end

    def player_news
      stories = $redis.smembers "news:#{@user.nation}"

      if !Util.news_open?
        @channel.msg 'The presses are currently stopped.'
      elsif stories.size == 0
        @channel.msg 'You have not submitted any stories.'
      else
        @channel.msg "_Here are your current stories as they will appear in the gazette_\n#{News.format(@user.nation, stories)}"
      end
    end

    def self.publish!(channel, force = false)
      if !force && !Util.news_open?
        channel.msg 'I cannot publish a gazette while the presses are stopped.'
        return
      end

      if $redis.keys('news:*').size == 0
        channel.msg 'I do not have any stories to publish.'
        return
      end

      output = ['_Here are the latest headlines from around Europe_']

      $redis.keys("news:*").each do |key|
        stories = $redis.smembers key
        country = key.match(/:(\w+)$/)[1]

        output << News.format(country, stories)

        $redis.del key
      end

      channel.msg output.join("\n")
    end

    def spike!
      nation = @user.nation

      if News.count_for(nation) == 0
        @channel.msg 'You had no stories to spike'
      else
        @channel.msg "I spiked your headline. It was: #{$redis.spop "news:#{nation}"}"
      end
    end

    def store!
      if Util.news_open?
        store_story
      else
        @channel.msg 'I am not currently accepting news stories'
      end
    end

    private

    def self.format(country, stories)
      output = []

      output += stories.map { |story| "*From #{country}:* \"#{story}\"" }

      output.join("\n")
    end

    def store_story
      text = @text.split.drop(1).join(' ')
      if $redis.sadd "news:#{@user.nation}", text
        @channel.msg "I have stored your \"#{text}\" story"
      else
        @channel.msg "It looks like I already had \"#{text}\" stored. You can say `mynews` to see your current news stories."
      end
    end
  end
end
