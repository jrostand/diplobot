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
      @channel.msg "`#{@command}` is not a command"
    end

    def respond_to_missing?(sym, include_private = false)
      true
    end

    private

    def admins
      if Util.admins.length == 1
        @channel.msg "My administrator is #{Util.oxfordise(Util.admin_tags)}."
      else
        @channel.msg "My administrators are #{Util.oxfordise(Util.admin_tags)}."
      end
    end

    def channel_only!
      raise InvalidChannelError if @channel.is_dm?
    end

    def dm_only!
      raise InvalidChannelError unless @channel.is_dm?
    end

    def deop(user)
      Util.remove_admin user

      @channel.msg "#{user} is no longer an administrator."
    rescue InvalidUserError
      @channel.msg "You cannot de-op the chief administrator."

      Util.message(
        Util.im_channel($chief_admin),
        "#{Util.tag_user(@user)} tried to de-op you. I won't let that happen."
      )
    end

    def help
      output = <<~EOF
        ```
        !deop USER     - Remove USER as an admin
        !help          - Display this message
        !news          - Publish a gazette of all available headlines
        !op USER       - Add USER as an admin
        !phase PHASE   - Set game phase to PHASE
                         (#{PhaseManager.new.phases.join('/')})
        !players       - Display the player mapping (may notify the users)
        !state         - Display the bot's state
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

    def phase(new_phase)
      channel_only!

      phase_mgr = PhaseManager.new
      phase_mgr.transition!(new_phase)

      @channel.msg "Current game phase is: #{phase_mgr}"

      case new_phase
      when 'build'
        @channel.msg 'Build/disband orders are being accepted'
      when 'diplomacy'
        @channel.msg 'Diplomacy is open and news submissions are being accepted'
      when 'orders'
        News.publish! @channel.id, true

        @channel.msg 'I am now accepting general orders'
      when 'retreat'
        @channel.msg 'I am now accepting retreat orders'
      when 'reveal'
        Order.reveal! @channel.id

        phase('resolution')
      when 'wait'
        @channel.msg 'The game is on hold until the scheduled start of the next phase'
      end
    rescue InvalidPhaseError
      @channel.msg "`#{new_phase}` is not a valid game phase. Valid phases are `#{phase_mgr.phases.join(' ')}`."
    rescue IllegalTransitionError
      @channel.msg "Cannot transition from #{phase_mgr.current_phase} to #{new_phase}"
    end

    def players
      @channel.msg("My player map is ( #{ENV['USER_MAP']} ).")
    end

    def state
      output = []
      phase_mgr = PhaseManager.new

      output << "The current phase is: #{phase_mgr}."

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

      @channel.msg output.join(' ')
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
