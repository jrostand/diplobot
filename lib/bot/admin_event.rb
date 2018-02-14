module Bot
  class AdminEvent < BaseModule
    def initialize(event)
      super event

      @command = @text.split.first.downcase.sub(/!/, '')
      @args = @text.split.drop(1)
    end

    def dispatch!
      method(@command.to_sym).call(*@args)
    rescue KarmaDecayError => e
      @channel.msg "You've done too much for now. Wait a few minutes."
    end

    def method_missing(sym, *args)
      @channel.msg "`#{@command}` is not a command"
    end

    def respond_to_missing?(sym, include_private = false)
      true
    end

    private

    def admin_only!
      unless @user.admin?
        if @channel.dm?
          raise InvalidChannelError
        else
          raise NotAuthorizedError
        end
      end
    end

    def admins
      admin_only!

      if Util.admins.length == 1
        @channel.msg "My administrator is #{Util.oxfordise(Util.admin_tags)}."
      else
        @channel.msg "My administrators are #{Util.oxfordise(Util.admin_tags)}."
      end
    end

    def channel_only!
      raise InvalidChannelError if @channel.dm?
    end

    def dm_only!
      raise InvalidChannelError unless @channel.dm?
    end

    def deop(user)
      admin_only!

      Util.remove_admin user

      @channel.msg "#{user} is no longer an administrator."
    rescue InvalidUserError
      @channel.msg "You cannot de-op the chief administrator."

      Util.im_channel($chief_admin).msg(
        "#{@user} tried to de-op you. I won't let that happen."
      )
    end

    def help
      admin_only!

      output = <<~EOF
        ```
        !deop USER          - Remove USER as an admin
        !help               - Display this message
        !news               - Publish a gazette of all available headlines
        !op USER            - Add USER as an admin
        !phase PHASE        - Set game phase to PHASE (#{PhaseManager.new.phases.join('/')})
        !player USER NATION - Set player of NATION to USER
        !players            - Display the player mapping (notifies the users)
        !state              - Display the bot's state
        !unlock NATION      - Unlock a nation's orders
        !unplayer USER      - Remove USER (and their nation) from the game
        ```
      EOF

      @channel.msg(output)
    end

    def news
      channel_only!
      require_karma! 2

      News.publish! @channel
    end

    def op(user)
      admin_only!

      Util.add_admin user

      @channel.msg "I have added #{user} as an administrator."
    end

    def phase(new_phase)
      admin_only!
      channel_only!

      phase_mgr = PhaseManager.new(@channel)
      phase_mgr.transition!(new_phase)
    end

    def player(username, nation)
      admin_only!

      raise InvalidNationError unless NATIONS.include?(nation)

      user_id = Util.user_id(username)

      raise InvalidUserError if $redis.hvals('players').include?(user_id)

      $redis.hset('players', nation, user_id)

      @channel.msg "#{Util.tag_user(username)} is now controlling #{nation}"
    rescue InvalidNationError
      @channel.msg "#{nation} is not a recognized nation. Valid options are #{Util.oxfordise(NATIONS, 'or')}."
    rescue InvalidUserError
      user_nation = $redis.hgetall('players').invert[user_id]

      @channel.msg "#{Util.tag_user(user_id)} is already playing as #{user_nation}."
    rescue NotFoundError => e
      @channel.msg e.message
    end

    def players
      if @channel.dm?
        require_karma! 2
      else
        admin_only!
      end

      if $redis.hlen('players') == 0
        output = 'There are no mapped players.'
      else
        output = "```\n"

        $redis.hgetall('players').each do |nation, user|
          output += "#{nation}: #{Util.tag_user(user)}\n"
        end

        output += '```'
      end

      @channel.msg(output)
    end

    def require_karma!(karma)
      return if @user.admin?

      raise NotAuthorizedError unless @user.karma.to_i >= karma

      @user.karma.decrement([2, karma].min)
    end

    def state
      require_karma! 6

      output = []
      phase_mgr = PhaseManager.new(@channel)

      output << "The current phase is: #{phase_mgr}."

      if Util.news_open?
        keys = $redis.keys('news:*')
        output << "There are #{keys.size == 0 ? 'no' : $redis.sunion(*keys).size} news stories ready for the gazette."
      end

      if Util.orders_open?
        countries = $redis.keys('lock:*').map { |key| key.split(':').last }
        output << "I have received locked-in orders from #{Util.oxfordise(countries)}."
      end

      @channel.msg output.join(' ')
    end

    def unlock(nation)
      admin_only!
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

    def unplayer(username)
      admin_only!

      uid = Util.user_id(username)

      raise InvalidUserError unless $redis.hvals('players').include?(uid)

      reverse_hash = $redis.hgetall('players').invert

      nation = reverse_hash[uid]

      $redis.hdel('players', nation)

      @channel.msg "#{Util.tag_user(uid)} is no longer playing as #{nation}."
    rescue InvalidUserError
      players = $redis.hvals('players').map { |user| Util.tag_user(user) }

      @channel.msg "#{Util.tag_user(uid)} is not a player. Valid options are #{Util.oxfordise(players, 'or')}."
    end
  end
end
