module Bot
  class AdminEvent
    def initialize(event)
      @channel = Channel.new(event)
      @text = event[:text]
      @user = event[:user]

      unless Util.is_admin?(@user)
        if @channel.is_dm?
          raise InvalidChannelError
        else
          raise NotAuthorizedError
        end
      end

      @command = @text.split.first.sub(/!/, '')
      @args = @text.split.drop(1)

      method(@command.to_sym).call(*@args)
    end

    def method_missing(sym)
      Util.message(Util.im_channel(@user), "I don't know what you meant by `#{@command}`")
    end

    def respond_to_missing?(sym, include_private = false)
      true
    end

    private

    def channel_only!
      raise InvalidChannelError if @channel.is_dm?
    end

    def close
      channel_only!

      Util.allow_orders false
      @channel.msg 'Orders are no longer being accepted'
    end

    def help
      output = <<~EOF
        ```
        !close      - Close bot to orders
        !help       - Display this message
        !news       - Publish a gazette of all available headlines
        !players    - Display the player mapping (may notify the users)
        !open       - Open bot to orders
        !reveal     - Reveal all orders (only if closed)
        !startpress - Allow news story submissions
        !state      - Display the bot's state
        !stoppress  - Cease allowing story submissions
        ```
      EOF

      @channel.msg(output)
    end

    def news
      channel_only!

      News.publish! @channel.id
    end

    def open
      channel_only!

      Util.allow_orders true
      @channel.msg 'I am now accepting orders'
    end

    def players
      @channel.msg("My player map is ( #{ENV['USER_MAP']} ).")
    end

    def reveal
      channel_only!

      Order.reveal! @channel.id
    end

    def startpress
      channel_only!

      Util.allow_news true
      @channel.msg 'Extra! Extra! I am now accepting news submissions!'
    end

    def state
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

      if $admin_tags.length == 1
        output << "My administrator is #{Util.oxfordise($admin_tags)}."
      else
        output << "My administrators are #{Util.oxfordise($admin_tags)}."
      end

      @channel.msg output.join(' ')
    end

    def stoppress
      channel_only!

      Util.allow_news false
      @channel.msg 'Stop the presses!'
    end
  end
end
