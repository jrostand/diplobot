module Bot
  class UserKarma
    def initialize(user_id)
      @user_id = user_id
    end

    def <(other)
      Karma.of(@user_id) < other
    end

    def >(other)
      Karma.of(@user_id) > other
    end

    def <=(other)
      Karma.of(@user_id) <= other
    end

    def >=(other)
      Karma.of(@user_id) >= other
    end

    def decrement(step = 1)
      Karma.decrement(@user_id, step)
    end

    def increment(step = 1)
      Karma.increment(@user_id, step)
    end

    def to_s
      Karma.of(@user_id)
    end
  end
end
