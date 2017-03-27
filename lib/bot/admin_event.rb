module Bot
  class AdminEvent
    class << self
      def dispatch(event)
        if !Util.is_admin?(event[:user])
          abuse!(event[:channel], event[:user])
          return
        end

        case event[:text]
        when '!open'
          allow_orders true
          Util.message(event[:channel], 'I am now accepting orders!')
        when '!close'
          allow_orders false
          Util.message(event[:channel], 'I am no longer accepting orders!')
        when '!reveal'
          Order.reveal! event[:channel]
        when '!news'
          News.display! event[:channel]
        when '!startpress'
          allow_news true
          Util.message(event[:channel], 'Extra! Extra! I am now accepting news submissions!')
        when '!state'
          show_state event[:channel]
        when '!stoppress'
          allow_news false
          Util.message(event[:channel], 'Stop the presses! I am no longer accepting news submissions!')
        when '!help'
          help_msg event[:channel]
        else
          Util.message(Util.im_channel(event[:user]), "I don't know what you mean by #{event[:text]}")
          return
        end
      end

      private

      def abuse!(channel, user)
        lines = [
          "You're not my real dad, #{Util.tag_user(user)}!",
          "You can't just order me around, #{Util.tag_user(user)}.",
          "I don't have to listen to you, #{Util.tag_user(user)}!",
          "Who do you think you are to command me, #{Util.tag_user(user)}?"
        ]

        Util.message(channel, lines.shuffle.first)
      end

      def allow_news(bool)
        status = bool ? 'open' : 'closed'

        $redis.set 'news_status', status
      end

      def allow_orders(bool)
        status = bool ? 'open' : 'closed'

        $redis.set 'orders_status', status
      end

      def help_msg(channel)
        output = <<~EOF
          ```
          Here are the available admin commands:

          !close      - Close bot to orders and stories
          !help       - Display this message
          !news       - Publish a gazette of all available headlines
          !open       - Accept orders and news stories
          !reveal     - Reveal all orders (only if closed)
          !startpress - Allow news story submissions
          !state      - Display the bot's state
          !stoppress  - Cease allowing story submissions
          ```
        EOF

        Util.message(channel, output)
      end

      def show_state(channel)
        output = []

        output << "My player map is ( #{ENV['USER_MAP']} )."

        if Util.news_open?
          output << "There are #{$redis.hlen('news')} news stories ready for the gazette."
        else
          output << 'The presses are stopped.'
        end

        if Util.orders_open?
          output << "I am accepting orders and have received them from #{$redis.hlen('orders')} players."
        else
          output << 'I am not accepting orders.'
        end

        output << "#{Util.tag_user(ENV['DIP_ADMIN'])} is my administrator."

        Util.message channel, output.join(' ')
      end
    end
  end
end
