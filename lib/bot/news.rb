module Bot
  class News
    def initialize(event)
      @event = event
      @channel = @event[:channel]
      @text = @event[:text].split[1..-1].join(' ')
      @uid = @event[:user]
    end

    def self.display!(channel)
      unless Util.news_open?
        Util.message channel, 'I cannot publish a gazette unless submissions are open.'
        return
      end

      if $redis.hlen('news') == 0
        Util.message channel, 'I do not have any stories to publish.'
        return
      end

      all_stories = []

      $redis.hkeys('news').each do |nation|
        stories = JSON.parse($redis.hget('news', nation)).map do |story|
          "*From #{nation}:* \"#{story}\""
        end

        all_stories += stories
      end

      output = ['_Here are the latest headlines from around Europe_']

      output += all_stories.shuffle

      $redis.del 'news'

      Util.message channel, output.join("\n")
    end

    def process!
      if Util.news_open?
        store_story
      else
        msg "I'm not currently accepting news stories"
      end
    end

    private

    def msg(text)
      Util.message(@channel, text)
    end

    def store_story
      username = Util.userinfo(@uid).name
      nation = $redis.hget('nations', username)

      stories = if $redis.hexists('news', nation)
                 JSON.parse($redis.hget('news', nation))
               else
                 []
               end

      stories << @text

      $redis.hset('news', nation, JSON.generate(stories))

      msg "I have stored your \"#{@text}\" story"
    end
  end
end
