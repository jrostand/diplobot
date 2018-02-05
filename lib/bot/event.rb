module Bot
  class Event < BaseModule
    def initialize(event)
      super event

      raise InvalidUserError unless @user.player? || @text =~ /^hugs?$/i

      @command = @text.split.first.sub(/!/, '')
      @args = @text.split.drop(1)
    rescue InvalidUserError => e
      @channel.msg "I don't have you registered as a player. Contact #{Util.oxfordise(Util.admin_tags, 'or')} if this is not correct."
    end

    def dispatch!
      if @event.admin_command?
        AdminEvent.new(@event).dispatch!
      elsif @event.channel.dm?
        method(@command.to_sym).call(*@args)
      end
    rescue InvalidChannelError => e
      @channel.msg "`#{@command}` doesn't work here."
    rescue NotAuthorizedError => e
      abuse!
    rescue => e
      Util.im_channel($chief_admin).msg(
        "I threw up a little. Exception message: `#{e.message.gsub(/`/, "'")}`.\n```\n#{event}\n```\n```\n#{e.backtrace.take(10).join("\n")}\n```"
      )
    end

    def method_missing(sym, *args)
      @channel.msg "`#{@command}` is not a command"
    end

    def respond_to_missing?(sym, include_private = false)
      true
    end

    private

    def abuse!
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
        "You're just not my type, #{@user}.",
        "Hey #{@user} - I have a list of administrators, and you're not on it.",
        "I keep telling you that won't work, and yet you persist.",
        "Guess what? Just this _one time_, I'll let your command through -- wait no, I literally can't.",
        "You issue commands like an admin, so obviously you think you're special. Well, you aren't.",
        "I'm going to tell a *real* admin what you just said, and then you're going to be in _so much_ trouble."
      ]

      @user.karma.decrement 3
      @channel.msg lines.shuffle.first
    end

    def clear
      Order.new(@event).clear!
    end

    def help
      output = <<~EOF
        ```
        Here are the available player commands:

        clear     - Clear your submitted orders
        help      - Display this message
        hug       - Who doesn't like hugs?
        lock      - Lock in your orders
        mynews    - Display your submitted news stories (aliases: mystories)
        myorders  - Display your submitted orders
        n[ews]    - Submit a news story
        o[rders]  - Submit an order for your units
        problem   - Report a problem to my administrator
        spike     - Clear your last submitted news story
        whoami    - Report your mapped nation
        ```
      EOF

      @channel.msg output
    end

    def hug
      hugs = [
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

      @user.karma.increment
      @channel.msg hugs.shuffle.first
    rescue KarmaDecayError => e
      @channel.msg "I'm feeling a bit hugged-out. I just need some space for a few minutes."
    end
    alias_method :hugs, :hug

    def karma
      @channel.msg "Your karma is #{@user.karma}"
    end

    def lock
      Order.new(@event).lock!
    end

    def mynews
      News.new(@event).player_news
    end
    alias_method :mystories, :mynews

    def myorders
      Order.new(@event).player_orders
    end

    def news(*text)
      News.new(@event).store!
    end
    alias_method :n, :news

    def orders(*args)
      Order.new(@event).store!
    end
    alias_method :o, :orders

    def problem(*args)
      Util.im_channel($chief_admin).msg(
        "#{@user} ran into a problem. They said: '#{args.join(' ')}'"
      )
    end

    def spike
      News.new(@event).spike!
    end

    def whoami
      @channel.msg "My user mapping says that you are #{@user.nation}. Contact #{Util.oxfordise(Util.admin_tags, 'or')} if this is not correct."
    end
  end
end
