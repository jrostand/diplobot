module Bot
  class Karma
    class << self
      def increment(user)
        unless has_karma?(user)
          make_karma(user)
        end

        karma = of(user) + 1

        $redis.set("karma:#{user}", karma)
      end

      def of(user)
        $redis.get("karma:#{user}").to_i
      end

      protected

      def has_karma?(user)
        $redis.exists "karma:#{user}"
      end

      def make_karma(user)
        $redis.set "karma:#{user}", 0
      end
    end
  end
end
