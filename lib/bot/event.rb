module Bot
  class Event
    class << self
      def dispatch(event)
        return if !event[:bot_id].nil? || event[:user] == $redis.get('bot_user')

        if !Util.is_player?(event[:user])
          msg "I don't have you registered as a player. Contact #{Util.tag_user(ENV['DIP_ADMIN'])} if this is not correct."
          return
        end

        case
        when event[:channel][0] == 'C' && event[:text][0] == '!'
          AdminEvent.dispatch event
        when event[:channel][0] == 'D'
          case
          when event[:text] =~ /^help$/i then help_msg(event[:channel])
          when event[:text] =~ /^o(rders?)?\s/i then Order.new(event).process!
          when event[:text] =~ /^n(ews)?\s/i then News.new(event).process!
          when event[:text] =~ /^clear$/i then clear_orders event
          when event[:text] =~ /^spike$/i then spike_news event
          when event[:text] =~ /^whoami$/i then whoami event
          end
        else
          if event[:channel][0] == 'D'
            Util.message event[:channel], "I don't know what you meant by \"#{event[:text]}\""
          end
        end
      end

      private

      def clear_orders(event)
        username = Util.userinfo(event[:user]).name

        begin
          orders = JSON.parse($redis.hget('orders', username)).join(', ')

          Util.message(event[:channel], "I have cleared your previous orders. They were: #{orders}")
        rescue => _
          Util.message(event[:channel], 'You had no orders to clear')
        end

        $redis.hdel 'orders', username
      end

      def help_msg(channel)
        output = <<~EOF
          ```
          Here are the available player commands:

          clear    - Clear your submitted orders
          help     - Display this message
          n[ews]   - Submit a news story
          o[rders] - Submit an order for your units
          spike    - Clear your submitted news stories
          whoami   - Report your mapped nation
          ```
        EOF

        Util.message(channel, output)
      end

      def spike_news(event)
        username = Util.userinfo(event[:user]).name
        nation = $redis.hget('nations', username)

        begin
          stories = JSON.parse($redis.hget('news', nation)).join(', ')

          Util.message(event[:channel], "I have spiked your headlines. They were: #{stories}")
        rescue => _
          Util.message(event[:channel], 'You had no stories to spike')
        end

        $redis.hdel 'news', nation
      end

      def whoami(event)
        username = Util.userinfo(event[:user]).name
        nation = $redis.hget('nations', username)

        Util.message(event[:channel], "My user mapping says that you are #{nation}. Contact #{Util.tag_user(ENV['DIP_ADMIN'])} if this is not correct.")
      end
    end
  end
end
