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

    def method_missing(sym, *args)
      Util.message(Util.im_channel(@user), "`#{@command}` is not a command")
    end

    def respond_to_missing?(sym, include_private = false)
      true
    end

    private

    def channel_only!
      raise InvalidChannelError if @channel.is_dm?
    end

    def dm_only!
      raise InvalidChannelError unless @channel.is_dm?
    end

    def close
      channel_only!

      Util.allow_orders false
      @channel.msg 'Orders are no longer being accepted'
    end

    def deop(user)
      Util.remove_admin user

      @channel.msg "#{user} is no longer an administrator."
    rescue Bot::InvalidUserError
      @channel.msg "You cannot de-op the chief administrator."

      Util.message(
        Util.im_channel($chief_admin),
        "#{Util.tag_user(@user)} tried to de-op you. I won't let that happen."
      )
    end

    def help
      output = <<~EOF
        ```
        !close         - Close bot to orders
        !deop USER     - Remove USER as an admin
        !help          - Display this message
        !news          - Publish a gazette of all available headlines
        !players       - Display the player mapping (may notify the users)
        !op USER       - Add USER as an admin
        !open          - Open bot to orders
        !reveal        - Reveal all orders (only if closed)
        !startpress    - Allow news story submissions
        !state         - Display the bot's state
        !stoppress     - Cease allowing story submissions
        !unlock NATION - Unlock a nation's orders
        ```
      EOF

      @channel.msg(output)
    end

    def news
      channel_only!

      News.publish! @channel.id
    end

    def op(user)
      Util.add_admin user

      @channel.msg "I have added #{user} as an administrator."
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
        countries = $redis.keys('lock:*').map { |key| key.split(':').last }
        output << "I have received locked-in orders from #{Util.oxfordise(countries)}."
      else
        output << 'I am not accepting orders.'
      end

      if Util.admins.length == 1
        output << "My administrator is #{Util.oxfordise(Util.admin_tags)}."
      else
        output << "My administrators are #{Util.oxfordise(Util.admin_tags)}."
      end

      @channel.msg output.join(' ')
    end

    def stoppress
      channel_only!

      Util.allow_news false
      @channel.msg 'Stop the presses!'
    end

    def unlock(nation)
      dm_only!

      locks = $redis.keys('lock:*').map { |key| key.split(':').last }

      if locks.size == 0
        @channel.msg 'No nations have locked in their orders'
        return
      end

      unless locks.include? nation
        @channel.msg "Invalid nation provided. Valid options are: #{Util.oxfordise(locks, 'or')}."
        return
      end

      $redis.del "lock:#{nation}"

      @channel.msg "Orders for #{nation} have been unlocked"
    end
  end
end
