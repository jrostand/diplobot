module Bot
  class Event
    class << self
      def dispatch(event)
        return if !event[:bot_id].nil? || event[:user] == $redis.get('bot_user')

        case
        when event[:channel][0] == 'C' && event[:text][0] == '!'
          AdminEvent.dispatch event
        when event[:channel][0] == 'D'
          if !Util.is_player?(event[:user])
            Util.message event[:channel], "I don't have you registered as a player. Contact #{Util.tag_user($admin)} if this is not correct."
            return
          end

          case
          when event[:text] =~ /^help$/i then help_msg(event[:channel])
          when event[:text] =~ /^o(rders?)?\s/i then Order.new(event).store!
          when event[:text] =~ /^myorders$/i then Order.new(event).player_orders
          when event[:text] =~ /^n(ews)?\s/i then News.new(event).store!
          when event[:text] =~ /^mystories$/i then News.new(event).player_news
          when event[:text] =~ /^clear$/i then clear_orders event
          when event[:text] =~ /^spike$/i then spike_news event
          when event[:text] =~ /^whoami$/i then whoami event
          when event[:text] =~ /^problem\s?/i then report event
          else
            Util.message event[:channel], "I don't know what you meant by \"#{event[:text]}\""
          end
        else
          if event[:channel][0] == 'D'
            Util.message event[:channel], "I don't know what you meant by \"#{event[:text]}\""
          end
        end
      end

      private

      def clear_orders(event)
        nation = $redis.hget('players', event[:user])

        orders = $redis.smembers("orders:#{nation}").join(', ')

        if orders.size == 0
          Util.message(event[:channel], 'You had no orders to clear')
        else
          Util.message(event[:channel], "I have cleared your previous orders. They were: #{orders}")
        end

        $redis.del "orders:#{nation}"
      end

      def help_msg(channel)
        output = <<~EOF
          ```
          Here are the available player commands:

          clear     - Clear your submitted orders
          help      - Display this message
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

      def report(event)
        text = event[:text].split[1..-1].join(' ')

        Util.message(
          Util.im_channel($admin),
          "#{Util.tag_user(event[:user])} ran into a problem. They said: '#{text}'"
        )
      end

      def spike_news(event)
        nation = $redis.hget('players', event[:user])

        stories = $redis.smembers("news:#{nation}").join(', ')

        if stories.size == 0
          Util.message(event[:channel], 'You had no stories to spike')
        else
          Util.message(event[:channel], "I have spiked your headlines. They were: #{stories}")
        end

        $redis.del "news:#{nation}"
      end

      def whoami(event)
        nation = $redis.hget('players', event[:user])

        Util.message(event[:channel], "My user mapping says that you are #{nation}. Contact #{Util.tag_user($admin)} if this is not correct.")
      end
    end
  end
end
