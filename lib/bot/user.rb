module Bot
  class User
    attr_reader :karma, :id

    def initialize(event)
      @id = event[:user]
      @karma = UserKarma.new(@id)
    end

    def self.new_by_id(id)
      new({ user: id })
    end

    def admin?
      Util.is_admin? id
    end

    def nation
      $redis.hgetall('players').invert[id]
    end

    def player?
      Util.is_player? id
    end

    def to_s
      Util.tag_user id
    end
  end
end
