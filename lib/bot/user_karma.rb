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

    def decrement(step = 1, force = false)
      Karma.decrement(@user_id, step, force)
    end

    def increment(step = 1)
      Karma.increment(@user_id, step)
    end

    def to_i
      Karma.of(@user_id).to_i
    end

    def to_s
      Karma.of(@user_id)
    end
  end
end
