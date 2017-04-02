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
          News.publish! event[:channel]
        when '!startpress'
          allow_news true
          Util.message(event[:channel], 'Extra! Extra! I am now accepting news submissions!')
        when '!state'
          show_state event[:channel]
        when '!players'
          show_players event[:channel]
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
          "You're not my real dad!",
          "You can't just order me around.",
          "I don't have to listen to you!",
          "Who do you think you are?",
          "You're not my supervisor!",
          "#{Util.tag_user($admin)} I need an adult!",
          "Stop trying to get me to do things.",
          "Quit poking me there, I don't like it.",
          "You're just not my type, #{Util.tag_user(user)}.",
          "I'm just checking my state now... how about that? It *doesn't* say, \"#{Util.tag_user(user)} is my administrator.\""
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
          !players    - Display the player mapping (WARNING: will notify the users)
          !open       - Accept orders and news stories
          !reveal     - Reveal all orders (only if closed)
          !startpress - Allow news story submissions
          !state      - Display the bot's state
          !stoppress  - Cease allowing story submissions
          ```
        EOF

        Util.message(channel, output)
      end

      def show_players(channel)
        Util.message channel, "My player map is ( #{ENV['USER_MAP']} )."
      end

      def show_state(channel)
        output = []

        if Util.news_open?
          keys = $redis.keys('news:*')
          output << "There are #{keys.size == 0 ? 'no' : $redis.sunion(*keys).size} news stories ready for the gazette."
        else
          output << 'The presses are stopped.'
        end

        if Util.orders_open?
          countries = $redis.keys('orders:*').map { |key| key.split(':').last }
          output << "I am accepting orders and have received them from #{Util.oxfordise(countries)}."
        else
          output << 'I am not accepting orders.'
        end

        output << "#{Util.tag_user($admin)} is my administrator."

        Util.message channel, output.join(' ')
      end
    end
  end
end
