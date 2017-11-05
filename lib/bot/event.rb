module Bot
  class Event
    class << self
      def dispatch(event)
        return if !event[:bot_id].nil? || event[:user] == $redis.get('bot_user')
        return unless event[:text]

        case
        when event[:text][0] == '!'
          AdminEvent.new event
        when event[:channel][0] == 'D'
          if !Util.is_player?(event[:user]) && event[:text] !~ /^hugs?$/i
            Util.message event[:channel], "I don't have you registered as a player. Contact #{Util.oxfordise(Util.admin_tags, 'or')} if this is not correct."
            return
          end

          case
          when event[:text] =~ /^help$/i then help_msg(event[:channel])
          when event[:text] =~ /^o(rders?)?\s/i then Order.new(event).store!
          when event[:text] =~ /^myorders$/i then Order.new(event).player_orders
          when event[:text] =~ /^lock$/i then Order.new(event).lock!
          when event[:text] =~ /^n(ews)?\s/i then News.new(event).store!
          when event[:text] =~ /^mystories$/i then News.new(event).player_news
          when event[:text] =~ /^clear$/i then Order.new(event).clear!
          when event[:text] =~ /^spike$/i then spike_news event
          when event[:text] =~ /^whoami$/i then whoami event
          when event[:text] =~ /^problem\s?/i then report event
          when event[:text] =~ /^hugs?$/i then hug event
          else
            Util.message event[:channel], "I don't know what you meant by \"#{event[:text]}\""
          end
        else
          if event[:channel][0] == 'D'
            Util.message event[:channel], "I don't know what you meant by \"#{event[:text]}\""
          end
        end
      rescue Bot::InvalidChannelError => e
        Util.message(event[:channel], "The `#{event[:text].split.first}` command doesn't work here.")
      rescue Bot::NotAuthorizedError => e
        abuse!(event)
      rescue => e
        Util.message(
          Util.im_channel($chief_admin),
          "I threw up a little. Exception message: `#{e.message.gsub(/`/, "'")}`.\n```\n#{event}\n```\n```\n#{e.backtrace.take(10).join("\n")}\n```"
        )
      end

      private

      def abuse!(event)
        user = event[:user]

        lines = [
          "Bad touch!",
          "You're not my real dad!",
          "You can't just order me around.",
          "I don't have to listen to you, so I won't.",
          "Who do you think you are?",
          "You're not my supervisor!",
          "#{Util.tag_user(Util.admins.shuffle.first)} I need an adult!",
          "Stop trying to get me to do things.",
          "Quit poking me there, I don't like it.",
          "You're just not my type, #{Util.tag_user(user)}.",
          "Hey #{Util.tag_user(user)} - I have a list of administrators, and you're not on it.",
          "I keep telling you that won't work, and yet you persist.",
          "Guess what? Just this _one time_, I'll let your command through -- wait no, I literally can't.",
          "You issue commands like an admin, so obviously you think you're special. Well, you aren't.",
          "I'm going to tell a *real* admin what you just said, and then you're going to be in _so much_ trouble."
        ]

        Util.message(event[:channel], lines.shuffle.first)
      end

      def help_msg(channel)
        output = <<~EOF
          ```
          Here are the available player commands:

          clear     - Clear your submitted orders
          help      - Display this message
          hug       - ¯\\_(ツ)_/¯
          lock      - Lock in your orders
          myorders  - Display your submitted orders
          mystories - Display your submitted news stories
          n[ews]    - Submit a news story
          o[rders]  - Submit an order for your units
          problem   - Report a problem to my administrator
          spike     - Clear your submitted news stories
          whoami    - Report your mapped nation
          ```
        EOF

        Util.message(channel, output)
      end

      def hug(event)
        things = [
          'https://i.chzbgr.com/full/8432724224/h2019AEDD.gif',
          'https://i.imgur.com/KGoEhLk.gif',
          'http://78.media.tumblr.com/3644cd3a73d4dd6ffbb18c65ad604988/tumblr_newvpiMsl11t4twpao1_1280.gif',
          'https://i.imgur.com/anqcRxv.gif',
          'https://i.imgur.com/8tEQrg3.gif',
          'http://www.reactiongifs.com/r/ywh.gif',
          'http://www.reactiongifs.com/r/nmrd.gif',
          'https://i.giphy.com/media/vRCSquxM3el6U/giphy.gif',
          'https://i.giphy.com/media/9MOUgVgxPBcL6/giphy.gif',
          'https://i.giphy.com/media/l0HlvU6gXnZHwnB3a/giphy.gif',
          'https://i.giphy.com/media/AU9st1hWuzMwU/giphy.gif',
          'https://i.giphy.com/media/1gbQIeNzZxcSk/giphy.gif'
        ]

        Karma.increment(event[:user])
        Util.message(event[:channel], things.shuffle.first)
        Util.message(
          Util.im_channel($chief_admin),
          "I got a hug from #{Util.tag_user(event[:user])}! Their karma is now #{Karma.of(event[:user])}."
        )
      end

      def report(event)
        text = event[:text].split[1..-1].join(' ')

        Util.message(
          Util.im_channel($chief_admin),
          "#{Util.tag_user(event[:user])} ran into a problem. They said: '#{text}'"
        )
      end

      def spike_news(event)
        nation = $redis.hgetall('players').invert[event[:user]]

        stories = $redis.smembers("news:#{nation}").join(', ')

        if stories.size == 0
          Util.message(event[:channel], 'You had no stories to spike')
        else
          Util.message(event[:channel], "I have spiked your headlines. They were: #{stories}")
        end

        $redis.del "news:#{nation}"
      end

      def whoami(event)
        nation = $redis.hgetall('players').invert[event[:user]]

        Util.message(event[:channel], "My user mapping says that you are #{nation}. Contact #{Util.oxfordise(Util.admin_tags, 'or')} if this is not correct.")
      end
    end
  end
end
